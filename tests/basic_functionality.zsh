#!/usr/bin/env zsh
# Basic functionality tests for dotfiles

test_essential_aliases() {
  echo "Testing essential aliases..."
  
  # Core aliases that should work everywhere
  local core_aliases=(status add commit new gl k gti bu refresh)
  # Platform-specific aliases that might not work in CI
  local platform_aliases=(j)
  
  local failed=0
  local skipped=0
  
  # Test core aliases
  for alias_name in $core_aliases; do
    if ! which $alias_name >/dev/null 2>&1; then
      echo "FAIL: Essential alias '$alias_name' not found"
      ((failed++))
    fi
  done
  
  # Test platform-specific aliases with CI awareness
  for alias_name in $platform_aliases; do
    if [[ -n "$CI" || -n "$GITHUB_ACTIONS" ]]; then
      echo "SKIP: Platform-specific alias '$alias_name' (CI mode)"
      ((skipped++))
    elif ! which $alias_name >/dev/null 2>&1; then
      echo "FAIL: Platform-specific alias '$alias_name' not found"
      ((failed++))
    fi
  done
  
  if [[ $failed -eq 0 ]]; then
    local total_tested=$((${#core_aliases[@]} + ${#platform_aliases[@]} - skipped))
    echo "PASS: All tested aliases found (${#core_aliases[@]} core + $((${#platform_aliases[@]} - skipped)) platform-specific)"
  else
    echo "FAIL: $failed essential aliases missing"
    return 1
  fi
}

test_git_aliases() {
  echo "Testing git aliases..."
  
  # Test that git aliases point to correct commands
  local git_status=$(alias status 2>/dev/null)
  [[ "$git_status" == *"git status"* ]] || { echo "FAIL: status alias incorrect"; return 1; }
  
  local git_add=$(alias add 2>/dev/null)
  [[ "$git_add" == *"git add ."* ]] || { echo "FAIL: add alias incorrect"; return 1; }
  
  local git_log=$(alias gl 2>/dev/null)
  [[ "$git_log" == *"git log --oneline"* ]] || { echo "FAIL: gl alias incorrect"; return 1; }
  
  echo "PASS: Git aliases correctly configured"
}

test_essential_functions() {
  echo "Testing essential functions..."
  local functions=(fix_colima_docker)
  local failed=0
  
  for func in $functions; do
    if ! type $func >/dev/null 2>&1; then
      echo "FAIL: Essential function '$func' not found"
      ((failed++))
    fi
  done
  
  if [[ $failed -eq 0 ]]; then
    echo "PASS: All essential functions found ($functions)"
  else
    echo "FAIL: $failed essential functions missing"
    return 1
  fi
}

test_git_utilities() {
  echo "Testing git utility functions..."
  local git_functions=(git_fix_rejected_push git_detect_rejected_files git_paste_fix)
  local failed=0
  
  for func in $git_functions; do
    if ! type $func >/dev/null 2>&1; then
      echo "FAIL: Git utility function '$func' not found"
      ((failed++))
    fi
  done
  
  if [[ $failed -eq 0 ]]; then
    echo "PASS: All git utility functions found ($git_functions)"
  else
    echo "FAIL: $failed git utility functions missing"
    return 1
  fi
}

test_lazy_loading_functions() {
  echo "Testing lazy loading functions are defined..."
  local lazy_functions=(nvm node npm)
  local failed=0
  
  for func in $lazy_functions; do
    if ! type $func >/dev/null 2>&1; then
      echo "FAIL: Lazy loading function '$func' not defined"
      ((failed++))
    else
      # Check it's actually a function, not the real binary
      local func_type=$(type $func 2>/dev/null)
      if [[ "$func_type" != *"shell function"* ]]; then
        echo "FAIL: '$func' is not a shell function (lazy loading failed)"
        ((failed++))
      fi
    fi
  done
  
  if [[ $failed -eq 0 ]]; then
    echo "PASS: All lazy loading functions properly defined"
  else
    echo "FAIL: $failed lazy loading functions not working"
    return 1
  fi
}

# Run all basic functionality tests
run_basic_tests() {
  echo "=== BASIC FUNCTIONALITY TESTS ==="
  local failed=0
  
  test_essential_aliases || ((failed++))
  test_git_aliases || ((failed++))
  test_essential_functions || ((failed++))
  test_git_utilities || ((failed++))
  test_lazy_loading_functions || ((failed++))
  
  if [[ $failed -eq 0 ]]; then
    echo "✓ All basic functionality tests passed"
    return 0
  else
    echo "✗ $failed basic functionality tests failed"
    return 1
  fi
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  run_basic_tests
fi