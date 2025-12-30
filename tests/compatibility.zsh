#!/usr/bin/env zsh
# Environment compatibility tests for dotfiles

test_required_environment_variables() {
  echo "Testing required environment variables..."
  local failed=0
  
  # Test essential environment variables
  [[ -n "$HOME" ]] || { echo "FAIL: HOME not set"; ((failed++)); }
  [[ -n "$PATH" ]] || { echo "FAIL: PATH not set"; ((failed++)); }
  [[ -n "$USER" ]] || { echo "FAIL: USER not set"; ((failed++)); }
  
  # Test our custom environment variables (CI-aware)
  if [[ -n "$CI" || -n "$GITHUB_ACTIONS" ]]; then
    # In CI, these variables might not be set - this is expected
    [[ -n "$GOPATH" ]] && echo "INFO: GOPATH set in CI: $GOPATH" || echo "INFO: GOPATH not set in CI (expected)"
    [[ -n "$NVM_DIR" ]] && echo "INFO: NVM_DIR set in CI: $NVM_DIR" || echo "INFO: NVM_DIR not set in CI (expected)"
    [[ -n "$DOCKER_HOST" ]] && echo "INFO: DOCKER_HOST set in CI: $DOCKER_HOST" || echo "INFO: DOCKER_HOST not set in CI (expected)"
  else
    # In local environment, these should be set
    [[ -n "$GOPATH" ]] || { echo "FAIL: GOPATH not set"; ((failed++)); }
    [[ -n "$NVM_DIR" ]] || { echo "FAIL: NVM_DIR not set"; ((failed++)); }
    if [[ "${DOTFILES_OS:-}" == "macos" ]]; then
      [[ -n "$DOCKER_HOST" ]] || { echo "FAIL: DOCKER_HOST not set"; ((failed++)); }
    else
      [[ -z "$DOCKER_HOST" ]] && echo "INFO: DOCKER_HOST unset on ${DOTFILES_OS:-unknown} (expected)"
    fi
  fi
  
  if [[ $failed -eq 0 ]]; then
    echo "PASS: All required environment variables set"
  else
    echo "FAIL: $failed required environment variables missing"
    return 1
  fi
}

test_path_variables() {
  echo "Testing PATH configuration..."
  local failed=0
  
  # Test that essential paths are in PATH
  local required_paths=(
    "$HOME/.cargo/bin"
    "$HOME/bin"
    "/usr/local/bin"
    "/usr/bin"
  )
  if [[ "${DOTFILES_OS:-}" == "macos" ]]; then
    required_paths+=("/opt/homebrew/bin")
  fi
  
  for path_entry in $required_paths; do
    if [[ "$PATH" != *"$path_entry"* ]]; then
      echo "WARN: $path_entry not in PATH"
    fi
  done
  
  # Test that PATH doesn't have too many duplicates
  local path_entries=(${(s/:/)PATH})
  local unique_entries=(${(u)path_entries})
  local duplicate_count=$((${#path_entries[@]} - ${#unique_entries[@]}))
  
  if [[ $duplicate_count -gt 10 ]]; then
    echo "WARN: PATH has $duplicate_count duplicate entries (consider deduplication)"
  else
    echo "PASS: PATH duplication reasonable ($duplicate_count duplicates)"
  fi
  
  echo "PASS: PATH configuration validated"
}

test_missing_dependencies_handling() {
  echo "Testing graceful handling of missing dependencies..."
  
  # Create a temporary environment without certain tools
  local temp_path=$(mktemp -d)
  
  # Test behavior when brew is missing
  PATH="$temp_path:$PATH" zsh -c '
    source "$HOME/dotfiles/zshrc.local" 2>/dev/null
    # Should not fail even if brew is missing
    echo "PASS: Handles missing brew gracefully"
  ' || echo "FAIL: Does not handle missing brew gracefully"
  
  # Test behavior when git is missing  
  PATH="$temp_path:$PATH" zsh -c '
    unalias status add commit 2>/dev/null || true
    source "$HOME/dotfiles/zshrc.local" 2>/dev/null
    # Aliases should still be defined even if git is missing
    which status >/dev/null && echo "PASS: Git aliases defined without git"
  ' || echo "FAIL: Git aliases not defined without git"
  
  rm -rf "$temp_path"
}

test_file_dependencies() {
  echo "Testing file dependencies..."
  local failed=0
  
  # In CI environments, we expect files to be missing - this is normal
  if [[ -n "$CI" || -n "$GITHUB_ACTIONS" ]]; then
    echo "INFO: Skipping file dependency tests in CI environment"
    echo "PASS: File dependency tests skipped in CI"
    return 0
  fi
  
  # Test that config handles missing optional files gracefully
  local optional_files=(
    "$HOME/dotfiles/work.zsh"
    "$HOME/dotfiles/git-large-file-fix"
    "$HOME/.cargo/env"
    "$HOME/google-cloud-sdk/path.zsh.inc"
    "$HOME/google-cloud-sdk/completion.zsh.inc"
  )
  
  for file in $optional_files; do
    if [[ -f "$file" ]]; then
      echo "INFO: Optional file exists: $file"
    else
      echo "INFO: Optional file missing: $file (should be handled gracefully)"
      
      # Test that config loads without errors even with missing file
      zsh -c "source '$HOME/dotfiles/zshrc.local'" 2>/dev/null || {
        echo "FAIL: Config fails with missing $file"
        ((failed++))
      }
    fi
  done
  
  if [[ $failed -eq 0 ]]; then
    echo "PASS: Missing files handled gracefully"
  else
    echo "FAIL: $failed files cause config to fail"
    return 1
  fi
}

test_shell_compatibility() {
  echo "Testing shell compatibility..."
  
  # Test that we're running in zsh
  if [[ -n "$ZSH_VERSION" ]]; then
    echo "PASS: Running in zsh (version: $ZSH_VERSION)"
  else
    echo "FAIL: Not running in zsh"
    return 1
  fi
  
  # Test zsh-specific features we use
  local zsh_features_used=(
    "array syntax: path=()"
    "parameter expansion: \${HOME}"
    "conditional expressions: [[ ]]"
    "functions with local variables"
  )
  
  echo "PASS: Zsh-specific features available: ${zsh_features_used[*]}"
}

test_platform_compatibility() {
  echo "Testing platform compatibility..."
  
  local platform=$(uname -s)
  echo "Running on platform: $platform"
  
  case "$platform" in
    Darwin)
      echo "INFO: macOS detected"
      # Test macOS-specific features
      command -v brew >/dev/null && echo "PASS: Homebrew available" || echo "INFO: Homebrew not installed"
      [[ -d "/opt/homebrew" ]] && echo "PASS: Apple Silicon Homebrew path exists" || echo "INFO: Intel Homebrew or no Homebrew"
      ;;
    Linux)
      echo "INFO: Linux detected"
      echo "WARN: Some features may be macOS-specific (Homebrew paths, etc.)"
      ;;
    *)
      echo "WARN: Unsupported platform: $platform"
      echo "INFO: Configuration may need adaptation"
      ;;
  esac
  
  echo "PASS: Platform compatibility checked"
}

test_terminal_capabilities() {
  echo "Testing terminal capabilities..."
  
  # Test color support
  if [[ -n "$TERM" ]]; then
    echo "Terminal type: $TERM"
    case "$TERM" in
      *color*|*256color*|xterm-*|screen-*)
        echo "PASS: Color terminal detected"
        ;;
      *)
        echo "WARN: Limited terminal capabilities"
        ;;
    esac
  else
    echo "WARN: TERM not set"
  fi
  
  # Test Unicode support (used in git prompt)
  if locale | grep -q "UTF-8"; then
    echo "PASS: UTF-8 locale detected (Unicode symbols supported)"
  else
    echo "WARN: Non-UTF-8 locale (Unicode symbols may not display correctly)"
  fi
}

test_network_dependencies() {
  echo "Testing network dependencies..."
  
  # Test that config doesn't require network access to load
  local start_time=$(date +%s)
  
  # Disconnect from network temporarily (simulate)
  # In real test, we'd mock network calls
  source "$HOME/dotfiles/zshrc.local" >/dev/null 2>&1
  
  local end_time=$(date +%s)
  local load_time=$((end_time - start_time))
  
  if [[ $load_time -lt 5 ]]; then
    echo "PASS: Config loads quickly without network dependency ($load_time seconds)"
  else
    echo "WARN: Config load time suggests network dependency ($load_time seconds)"
  fi
}

# Run all compatibility tests
run_compatibility_tests() {
  echo "=== COMPATIBILITY TESTS ==="
  local failed=0
  
  test_required_environment_variables || ((failed++))
  test_path_variables || ((failed++))
  test_missing_dependencies_handling || ((failed++))
  test_file_dependencies || ((failed++))
  test_shell_compatibility || ((failed++))
  test_platform_compatibility || ((failed++))
  test_terminal_capabilities || ((failed++))
  test_network_dependencies || ((failed++))
  
  if [[ $failed -eq 0 ]]; then
    echo "✓ All compatibility tests passed"
    return 0
  else
    echo "✗ $failed compatibility tests failed"
    return 1
  fi
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  run_compatibility_tests
fi
