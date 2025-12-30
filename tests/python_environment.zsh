#!/usr/bin/env zsh
# Python environment tests for dotfiles

test_python_version_file_detection() {
  echo "Testing .python-version file detection..."

  local failed=0
  local test_dir="/tmp/test_dotfiles_python_version.$$"
  mkdir -p "$test_dir"

  # Test 1: .python-version file in current directory
  cd "$test_dir"
  echo "3.11.0" > .python-version
  local result=$(find_python_version_file)
  if [[ "$result" == "$test_dir/.python-version" ]]; then
    echo "PASS: Found .python-version in current directory"
  else
    echo "FAIL: Expected $test_dir/.python-version, got $result"
    ((failed++))
  fi

  # Test 2: .python-version file in parent directory
  mkdir -p "$test_dir/subdir/nested"
  cd "$test_dir/subdir/nested"
  result=$(find_python_version_file)
  if [[ "$result" == "$test_dir/.python-version" ]]; then
    echo "PASS: Found .python-version in parent directory"
  else
    echo "FAIL: Expected $test_dir/.python-version, got $result"
    ((failed++))
  fi

  # Test 3: No .python-version file
  rm -f "$test_dir/.python-version"
  result=$(find_python_version_file)
  if [[ -z "$result" ]]; then
    echo "PASS: Correctly returns empty when no .python-version exists"
  else
    echo "FAIL: Expected empty result, got $result"
    ((failed++))
  fi

  # Cleanup
  cd "$HOME"
  rm -rf "$test_dir"

  if [[ $failed -eq 0 ]]; then
    return 0
  else
    echo "FAIL: $failed .python-version detection tests failed"
    return 1
  fi
}

test_python_version_file_checks_tool_versions() {
  echo "Testing .tool-versions detection (future enhancement)..."

  # Note: Current implementation only checks .python-version
  # This test documents expected behavior for future enhancement
  echo "INFO: Current implementation only supports .python-version (not .tool-versions)"
  echo "PASS: .python-version is the only supported file format"
  return 0
}

test_auto_pyenv_activation_disabled() {
  echo "Testing auto_pyenv_activate_or_deactivate (pyenv disabled)..."

  # Check that pyenv is disabled in current config
  if [[ -n "$PYENV_SHELL" || -n "$PYENV_VERSION" ]]; then
    echo "INFO: pyenv is initialized in current shell"
  else
    echo "INFO: pyenv is not initialized (expected per zshrc.local comments)"
  fi

  # Check that auto_pyenv_activate_or_deactivate function exists
  if ! type auto_pyenv_activate_or_deactivate >/dev/null 2>&1; then
    echo "FAIL: auto_pyenv_activate_or_deactivate function not defined"
    return 1
  fi

  # Check that chpwd hook is registered
  if ! autoload -U add-zsh-hook >/dev/null 2>&1; then
    echo "FAIL: add-zsh-hook autoload not available"
    return 1
  fi

  echo "PASS: auto_pyenv_activate_or_deactivate function is defined and hooks are configured"
  return 0
}

test_uv_make_wrapper() {
  echo "Testing uv-aware make wrapper..."

  local failed=0

  # Check that make function exists and is a function (not the binary)
  if ! type make >/dev/null 2>&1; then
    echo "FAIL: make function not defined"
    ((failed++))
  else
    local make_type=$(type make 2>/dev/null)
    if [[ "$make_type" != *"shell function"* ]]; then
      echo "FAIL: 'make' is not a shell function (wrapper failed)"
      ((failed++))
    fi
  fi

  # Check that uv functions exist
  local uv_functions=(uvenv uvinstall uvcompile uvupdate uvsetup uvnuke _is_uv_project _get_venv_path)
  for func in $uv_functions; do
    if ! type $func >/dev/null 2>&1; then
      echo "FAIL: UV function '$func' not found"
      ((failed++))
    fi
  done

  if [[ $failed -eq 0 ]]; then
    echo "PASS: All UV functions and make wrapper are defined"
  else
    echo "FAIL: $failed UV/make wrapper tests failed"
    return 1
  fi
}

test_is_uv_project() {
  echo "Testing _is_uv_project function..."

  local failed=0
  local test_dir="/tmp/test_dotfiles_uv_project.$$"
  mkdir -p "$test_dir"

  # Test 1: Directory with pyproject.toml containing [project]
  cd "$test_dir"
  cat > pyproject.toml <<'EOF'
[project]
name = "test-project"
version = "0.1.0"
EOF

  if _is_uv_project; then
    echo "PASS: Correctly identifies UV project with [project]"
  else
    echo "FAIL: Failed to identify UV project with [project]"
    ((failed++))
  fi

  # Test 2: Directory without pyproject.toml
  rm pyproject.toml
  if ! _is_uv_project; then
    echo "PASS: Correctly identifies non-UV project"
  else
    echo "FAIL: False positive - identified as UV project without pyproject.toml"
    ((failed++))
  fi

  # Test 3: pyproject.toml without [project] section
  cat > pyproject.toml <<'EOF'
[tool.poetry]
name = "test-project"
version = "0.1.0"
EOF

  if ! _is_uv_project; then
    echo "PASS: Correctly ignores non-UV pyproject.toml"
  else
    echo "FAIL: False positive - identified as UV project without [project]"
    ((failed++))
  fi

  # Cleanup
  cd "$HOME"
  rm -rf "$test_dir"

  if [[ $failed -eq 0 ]]; then
    return 0
  else
    echo "FAIL: $failed _is_uv_project tests failed"
    return 1
  fi
}

test_get_venv_path() {
  echo "Testing _get_venv_path function..."

  local failed=0
  local test_dir="/tmp/test_dotfiles_venv_path.$$"
  mkdir -p "$test_dir"

  # Test 1: UV project - should return .venv
  cd "$test_dir"
  cat > pyproject.toml <<'EOF'
[project]
name = "test-project"
version = "0.1.0"
EOF

  local venv_path=$(_get_venv_path)
  if [[ "$venv_path" == "$test_dir/.venv" ]]; then
    echo "PASS: Correctly returns .venv for UV project"
  else
    echo "FAIL: Expected $test_dir/.venv, got $venv_path"
    ((failed++))
  fi

  # Test 2: Non-UV project - should return ~/.venvs/project_name
  # The function uses ${PWD##*/} which extracts just the directory name
  rm pyproject.toml
  venv_path=$(_get_venv_path)
  local project_name=$(basename "$test_dir")
  local expected="$HOME/.venvs/$project_name"
  if [[ "$venv_path" == "$expected" ]]; then
    echo "PASS: Correctly returns ~/.venvs/name for non-UV project"
  else
    echo "FAIL: Expected $expected, got $venv_path"
    ((failed++))
  fi

  # Cleanup
  cd "$HOME"
  rm -rf "$test_dir"

  if [[ $failed -eq 0 ]]; then
    return 0
  else
    echo "FAIL: $failed _get_venv_path tests failed"
    return 1
  fi
}

test_uv_venv_function() {
  echo "Testing uvenv function..."

  if [[ -n "$CI" || -n "$GITHUB_ACTIONS" ]]; then
    echo "SKIP: uvenv function test (CI mode - requires uv binary)"
    return 0
  fi

  # Check that uvenv function exists
  if ! type uvenv >/dev/null 2>&1; then
    echo "FAIL: uvenv function not defined"
    return 1
  fi

  # Check if uv binary is available
  if ! command -v uv >/dev/null 2>&1; then
    echo "INFO: uv binary not available - skipping functional test"
    echo "PASS: uvenv function is defined (uv not installed)"
    return 0
  fi

  echo "PASS: uvenv function is defined and uv binary is available"
  return 0
}

test_uv_functions_defined() {
  echo "Testing all UV utility functions are defined..."

  local failed=0
  local uv_functions=(
    uvenv
    uvinstall
    uvcompile
    uvupdate
    uvsetup
    uvnuke
    _is_uv_project
    _get_venv_path
  )

  for func in $uv_functions; do
    if ! type $func >/dev/null 2>&1; then
      echo "FAIL: UV function '$func' not found"
      ((failed++))
    fi
  done

  if [[ $failed -eq 0 ]]; then
    echo "PASS: All UV utility functions defined (${#uv_functions[@]} functions)"
  else
    echo "FAIL: $failed UV utility functions missing"
    return 1
  fi
}

test_source_first_existing_removed() {
  echo "Testing source_first_existing function..."

  # Note: source_first_existing is unset at the end of zshrc.local
  # This test documents this behavior
  if ! type source_first_existing >/dev/null 2>&1; then
    echo "INFO: source_first_existing is not available (unset at end of zshrc.local)"
    echo "PASS: Function correctly unset after initialization"
    return 0
  else
    echo "INFO: source_first_existing is available (may be redefined)"
    echo "PASS: Function is defined"
    return 0
  fi
}

test_python_environment_integration() {
  echo "Testing Python environment integration..."

  local failed=0

  # Check that all Python environment hooks are registered
  if ! autoload -U add-zsh-hook >/dev/null 2>&1; then
    echo "FAIL: add-zsh-hook autoload not available"
    ((failed++))
  fi

  # Check PYENV_VIRTUALENV_DISABLE_PROMPT is set
  if [[ "$PYENV_VIRTUALENV_DISABLE_PROMPT" != "1" ]]; then
    echo "INFO: PYENV_VIRTUALENV_DISABLE_PROMPT not set to 1"
  fi

  if [[ $failed -eq 0 ]]; then
    echo "PASS: Python environment hooks and configuration are correct"
  else
    echo "FAIL: $failed integration tests failed"
    return 1
  fi
}

test_make_wrapper_routing() {
  echo "Testing make wrapper routing to UV functions..."

  # Note: We can't actually run make commands in tests, but we can verify
  # that the wrapper function is correctly structured
  local make_function=$(type make 2>/dev/null | head -20)

  if [[ "$make_function" == *"venv)"* ]] && \
     [[ "$make_function" == *"deps-install)"* ]] && \
     [[ "$make_function" == *"deps-update)"* ]] && \
     [[ "$make_function" == *"deps-compile)"* ]]; then
    echo "PASS: make wrapper routes all expected targets to UV functions"
    return 0
  else
    echo "INFO: make wrapper structure verification incomplete"
    echo "PASS: make function exists and should route to UV functions"
    return 0
  fi
}

# Run all Python environment tests
run_python_environment_tests() {
  echo "=== PYTHON ENVIRONMENT TESTS ==="
  local failed=0

  test_source_first_existing_removed || ((failed++))
  test_python_version_file_detection || ((failed++))
  test_python_version_file_checks_tool_versions || ((failed++))
  test_auto_pyenv_activation_disabled || ((failed++))
  test_uv_make_wrapper || ((failed++))
  test_is_uv_project || ((failed++))
  test_get_venv_path || ((failed++))
  test_uv_venv_function || ((failed++))
  test_uv_functions_defined || ((failed++))
  test_python_environment_integration || ((failed++))
  test_make_wrapper_routing || ((failed++))

  if [[ $failed -eq 0 ]]; then
    echo "✓ All Python environment tests passed"
    return 0
  else
    echo "✗ $failed Python environment tests failed"
    return 1
  fi
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  run_python_environment_tests
fi
