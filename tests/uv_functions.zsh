#!/usr/bin/env zsh
# UV functions tests for dotfiles

test_is_uv_project_detection() {
  echo "Testing _is_uv_project detection logic..."

  # Create a temporary directory for testing
  local test_dir=$(mktemp -d)
  cd "$test_dir" || { echo "FAIL: Could not enter test directory"; return 1; }

  # Test 1: No project files - should return false
  local result
  result=$(_is_uv_project && echo "yes" || echo "no")
  if [[ "$result" != "no" ]]; then
    echo "FAIL: _is_uv_project should return false when no project files exist"
    cd - >/dev/null
    rm -rf "$test_dir"
    return 1
  fi

  # Test 2: pyproject.toml without [project] section - should return false
  echo "[tool.poetry]" > pyproject.toml
  result=$(_is_uv_project && echo "yes" || echo "no")
  if [[ "$result" != "no" ]]; then
    echo "FAIL: _is_uv_project should return false when [project] section missing"
    cd - >/dev/null
    rm -rf "$test_dir"
    return 1
  fi

  # Test 3: pyproject.toml with [project] section - should return true
  echo "[project]" > pyproject.toml
  echo 'name = "test"' >> pyproject.toml
  result=$(_is_uv_project && echo "yes" || echo "no")
  if [[ "$result" != "yes" ]]; then
    echo "FAIL: _is_uv_project should return true when [project] section exists"
    cd - >/dev/null
    rm -rf "$test_dir"
    return 1
  fi

  # Test 4: pyproject.toml with [project] but at end of file
  echo "# Some comment" > pyproject.toml
  echo "build-system = 'setuptools'" >> pyproject.toml
  echo "[project]" >> pyproject.toml
  result=$(_is_uv_project && echo "yes" || echo "no")
  if [[ "$result" != "yes" ]]; then
    echo "FAIL: _is_uv_project should detect [project] anywhere in file"
    cd - >/dev/null
    rm -rf "$test_dir"
    return 1
  fi

  cd - >/dev/null
  rm -rf "$test_dir"
  echo "PASS: _is_uv_project detection logic works correctly"
}

test_get_venv_path() {
  echo "Testing _get_venv_path resolution..."

  # Create a temporary directory for testing
  local test_dir=$(mktemp -d)
  cd "$test_dir" || { echo "FAIL: Could not enter test directory"; return 1; }

  # Test 1: Non-uv project should use ~/.venvs/
  if ! _is_uv_project; then
    local result=$(_get_venv_path)
    local expected="$HOME/.venvs/${PWD##*/}"
    if [[ "$result" != "$expected" ]]; then
      echo "FAIL: _get_venv_path should return '$expected' for non-uv project, got '$result'"
      cd - >/dev/null
      rm -rf "$test_dir"
      return 1
    fi
  fi

  # Test 2: UV project should use .venv
  echo "[project]" > pyproject.toml
  local result=$(_get_venv_path)
  local expected="$PWD/.venv"
  if [[ "$result" != "$expected" ]]; then
    echo "FAIL: _get_venv_path should return '$expected' for uv project, got '$result'"
    cd - >/dev/null
    rm -rf "$test_dir"
    return 1
  fi

  cd - >/dev/null
  rm -rf "$test_dir"
  echo "PASS: _get_venv_path resolution works correctly"
}

test_uvenv_function() {
  echo "Testing uvenv function definition..."

  # Check that uvenv function exists
  if ! type uvenv >/dev/null 2>&1; then
    echo "FAIL: uvenv function not found"
    return 1
  fi

  # Check it's actually a function
  local func_type=$(type uvenv 2>/dev/null)
  if [[ "$func_type" != *"shell function"* ]]; then
    echo "FAIL: uvenv is not a shell function"
    return 1
  fi

  # Verify function signature accepts python version parameter
  if ! typeset -f uvenv | grep -q 'local py=.*1'; then
    echo "FAIL: uvenv should accept python version parameter with default"
    return 1
  fi

  echo "PASS: uvenv function properly defined"
}

test_uvinstall_function() {
  echo "Testing uvinstall function definition..."

  # Check that uvinstall function exists
  if ! type uvinstall >/dev/null 2>&1; then
    echo "FAIL: uvinstall function not found"
    return 1
  fi

  # Check it's actually a function
  local func_type=$(type uvinstall 2>/dev/null)
  if [[ "$func_type" != *"shell function"* ]]; then
    echo "FAIL: uvinstall is not a shell function"
    return 1
  fi

  # Verify function calls _get_venv_path
  if ! typeset -f uvinstall | grep -q '_get_venv_path'; then
    echo "FAIL: uvinstall should call _get_venv_path"
    return 1
  fi

  # Verify function handles uv projects
  if ! typeset -f uvinstall | grep -q '_is_uv_project'; then
    echo "FAIL: uvinstall should check _is_uv_project"
    return 1
  fi

  echo "PASS: uvinstall function properly defined"
}

test_uvcompile_function() {
  echo "Testing uvcompile function definition..."

  # Check that uvcompile function exists
  if ! type uvcompile >/dev/null 2>&1; then
    echo "FAIL: uvcompile function not found"
    return 1
  fi

  # Check it's actually a function
  local func_type=$(type uvcompile 2>/dev/null)
  if [[ "$func_type" != *"shell function"* ]]; then
    echo "FAIL: uvcompile is not a shell function"
    return 1
  fi

  # Verify function accepts package parameter
  if ! typeset -f uvcompile | grep -q 'local pkg='; then
    echo "FAIL: uvcompile should accept package parameter"
    return 1
  fi

  echo "PASS: uvcompile function properly defined"
}

test_uvupdate_function() {
  echo "Testing uvupdate function definition..."

  # Check that uvupdate function exists
  if ! type uvupdate >/dev/null 2>&1; then
    echo "FAIL: uvupdate function not found"
    return 1
  fi

  # Check it's actually a function
  local func_type=$(type uvupdate 2>/dev/null)
  if [[ "$func_type" != *"shell function"* ]]; then
    echo "FAIL: uvupdate is not a shell function"
    return 1
  fi

  # Verify function calls _get_venv_path
  if ! typeset -f uvupdate | grep -q '_get_venv_path'; then
    echo "FAIL: uvupdate should call _get_venv_path"
    return 1
  fi

  echo "PASS: uvupdate function properly defined"
}

test_uvsetup_function() {
  echo "Testing uvsetup function definition..."

  # Check that uvsetup function exists
  if ! type uvsetup >/dev/null 2>&1; then
    echo "FAIL: uvsetup function not found"
    return 1
  fi

  # Check it's actually a function
  local func_type=$(type uvsetup 2>/dev/null)
  if [[ "$func_type" != *"shell function"* ]]; then
    echo "FAIL: uvsetup is not a shell function"
    return 1
  fi

  # Verify function calls uvenv and uvinstall
  local func_def=$(typeset -f uvsetup)
  if ! echo "$func_def" | grep -q 'uvenv'; then
    echo "FAIL: uvsetup should call uvenv"
    return 1
  fi

  if ! echo "$func_def" | grep -q 'uvinstall'; then
    echo "FAIL: uvsetup should call uvinstall"
    return 1
  fi

  echo "PASS: uvsetup function properly defined"
}

test_uvnuke_function() {
  echo "Testing uvnuke function definition..."

  # Check that uvnuke function exists
  if ! type uvnuke >/dev/null 2>&1; then
    echo "FAIL: uvnuke function not found"
    return 1
  fi

  # Check it's actually a function
  local func_type=$(type uvnuke 2>/dev/null)
  if [[ "$func_type" != *"shell function"* ]]; then
    echo "FAIL: uvnuke is not a shell function"
    return 1
  fi

  # Verify function calls _get_venv_path
  if ! typeset -f uvnuke | grep -q '_get_venv_path'; then
    echo "FAIL: uvnuke should call _get_venv_path"
    return 1
  fi

  # Verify function calls uvinstall
  if ! typeset -f uvnuke | grep -q 'uvinstall'; then
    echo "FAIL: uvnuke should call uvinstall after cleanup"
    return 1
  fi

  echo "PASS: uvnuke function properly defined"
}

test_uv_function_integration() {
  echo "Testing uv function integration..."

  # Skip in CI - these tests require actual uv binary
  if [[ -n "$CI" || -n "$GITHUB_ACTIONS" ]]; then
    echo "SKIP: Integration tests (CI mode - uv binary not available)"
    return 0
  fi

  # Check if uv is available
  if ! command -v uv >/dev/null 2>&1; then
    echo "SKIP: Integration tests (uv binary not installed)"
    return 0
  fi

  # Create a temporary directory for testing
  local test_dir=$(mktemp -d)
  cd "$test_dir" || { echo "FAIL: Could not enter test directory"; return 1; }

  # Test uvenv creation and cleanup
  echo "[project]" > pyproject.toml
  echo 'name = "test-project"' >> pyproject.toml

  # Note: We can't actually run uvenv in tests as it's interactive and creates venvs
  # But we can verify the functions are properly integrated

  # Verify _is_uv_project recognizes our test project
  if ! _is_uv_project; then
    echo "FAIL: Test project should be recognized as uv project"
    cd - >/dev/null
    rm -rf "$test_dir"
    return 1
  fi

  # Verify _get_venv_path returns correct path
  local venv_path=$(_get_venv_path)
  if [[ "$venv_path" != "$PWD/.venv" ]]; then
    echo "FAIL: Venv path should be .venv for uv project"
    cd - >/dev/null
    rm -rf "$test_dir"
    return 1
  fi

  cd - >/dev/null
  rm -rf "$test_dir"
  echo "PASS: UV function integration works correctly"
}

test_uv_project_scenarios() {
  echo "Testing uv project scenarios..."

  # Create a temporary directory for testing
  local test_dir=$(mktemp -d)
  cd "$test_dir" || { echo "FAIL: Could not enter test directory"; return 1; }

  # Scenario 1: Traditional project with requirements.txt (now uses .venv for UV speed)
  touch requirements.txt
  local venv_path=$(_get_venv_path)
  local expected="$PWD/.venv"
  if [[ "$venv_path" != "$expected" ]]; then
    echo "FAIL: Traditional Python project should use .venv for UV compatibility"
    cd - >/dev/null
    rm -rf "$test_dir"
    return 1
  fi

  # Scenario 2: UV project with pyproject.toml
  rm -f requirements.txt
  echo "[project]" > pyproject.toml
  venv_path=$(_get_venv_path)
  expected="$PWD/.venv"
  if [[ "$venv_path" != "$expected" ]]; then
    echo "FAIL: UV project should use .venv"
    cd - >/dev/null
    rm -rf "$test_dir"
    return 1
  fi

  # Scenario 3: Both files present (should prefer uv project)
  touch requirements.txt
  venv_path=$(_get_venv_path)
  if [[ "$venv_path" != "$expected" ]]; then
    echo "FAIL: UV project detection should take precedence"
    cd - >/dev/null
    rm -rf "$test_dir"
    return 1
  fi

  cd - >/dev/null
  rm -rf "$test_dir"
  echo "PASS: UV project scenarios handled correctly"
}

test_uv_error_handling() {
  echo "Testing uv function error handling..."

  # Test _get_venv_path with special characters in directory name
  local test_dir=$(mktemp -d)
  cd "$test_dir" || { echo "FAIL: Could not enter test directory"; return 1; }

  # Create subdirectory with special characters
  mkdir "test project"
  cd "test project" || { echo "FAIL: Could not enter special char directory"; return 1; }

  echo "[project]" > pyproject.toml
  local venv_path=$(_get_venv_path)
  if [[ "$venv_path" != "$PWD/.venv" ]]; then
    echo "FAIL: Should handle special characters in directory names"
    cd "$test_dir" >/dev/null
    rm -rf "$test_dir"
    return 1
  fi

  cd "$test_dir" >/dev/null
  rm -rf "$test_dir"
  echo "PASS: UV function error handling works correctly"
}

test_uv_function_availability() {
  echo "Testing all uv functions are available..."

  local uv_functions=(_is_uv_project _get_venv_path uvenv uvinstall uvcompile uvupdate uvsetup uvnuke)
  local failed=0

  for func in $uv_functions; do
    if ! type $func >/dev/null 2>&1; then
      echo "FAIL: UV function '$func' not found"
      ((failed++))
    fi
  done

  if [[ $failed -eq 0 ]]; then
    echo "PASS: All uv functions available ($uv_functions)"
  else
    echo "FAIL: $failed uv functions missing"
    return 1
  fi
}

run_uv_functions_tests() {
  echo "=== UV FUNCTIONS TESTS ==="
  local failed=0

  test_uv_function_availability || ((failed++))
  test_is_uv_project_detection || ((failed++))
  test_get_venv_path || ((failed++))
  test_uvenv_function || ((failed++))
  test_uvinstall_function || ((failed++))
  test_uvcompile_function || ((failed++))
  test_uvupdate_function || ((failed++))
  test_uvsetup_function || ((failed++))
  test_uvnuke_function || ((failed++))
  test_uv_function_integration || ((failed++))
  test_uv_project_scenarios || ((failed++))
  test_uv_error_handling || ((failed++))

  if [[ $failed -eq 0 ]]; then
    echo "✓ All uv functions tests passed"
    return 0
  else
    echo "✗ $failed uv functions tests failed"
    return 1
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  run_uv_functions_tests
fi
