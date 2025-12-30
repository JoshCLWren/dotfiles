#!/usr/bin/env zsh
# Tests for helper scripts and pdbrc.py

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)"

test_helper_scripts_exist() {
  echo "Testing helper scripts exist and are executable..."

  local scripts=(
    "gcloud_auto_auth.py"
    "kubectl-diagnose.sh"
    "kubectl-quick-test.sh"
    "sync-terminal-history.sh"
    "evalcache.zsh"
  )

  local failed=0

  for script in $scripts; do
    local script_path="$DOTFILES_DIR/$script"
    
    if [[ ! -f "$script_path" ]]; then
      echo "FAIL: Helper script '$script' not found"
      ((failed++))
    elif [[ ! -r "$script_path" ]]; then
      echo "FAIL: Helper script '$script' is not readable"
      ((failed++))
    elif [[ "$script" != *.zsh ]] && [[ ! -x "$script_path" ]]; then
      echo "FAIL: Helper script '$script' is not executable"
      ((failed++))
    else
      echo "PASS: Helper script '$script' exists and is $( [[ "$script" == *.zsh ]] && echo "readable" || echo "executable")"
    fi
  done

  if [[ $failed -eq 0 ]]; then
    echo "PASS: All helper scripts found and accessible"
  else
    echo "FAIL: $failed helper scripts missing or inaccessible"
    return 1
  fi
}

test_gcloud_auto_auth() {
  echo "Testing gcloud_auto_auth.py..."

  local script_path="$DOTFILES_DIR/gcloud_auto_auth.py"
  local failed=0

  # Check shebang and Python requirements
  if ! head -1 "$script_path" | grep -q python; then
    echo "FAIL: gcloud_auto_auth.py doesn't have a Python shebang"
    ((failed++))
  fi

  # Check for required imports
  local required_imports=(subprocess re sys os tempfile json playwright)
  for import in $required_imports; do
    if ! grep -q "import $import\|from $import" "$script_path"; then
      echo "FAIL: gcloud_auto_auth.py missing required import: $import"
      ((failed++))
    fi
  done

  # Check for main function
  if ! grep -q "^def main():" "$script_path"; then
    echo "FAIL: gcloud_auto_auth.py missing main() function"
    ((failed++))
  fi

  # Check if python3 is available (CI-aware)
  if command -v python3 >/dev/null 2>&1; then
    # Try to parse the Python file to check syntax
    if ! python3 -m py_compile "$script_path" 2>/dev/null; then
      echo "FAIL: gcloud_auto_auth.py has syntax errors"
      ((failed++))
    fi
  else
    echo "SKIP: Python3 not available for syntax check (CI mode)"
  fi

  if [[ $failed -eq 0 ]]; then
    echo "PASS: gcloud_auto_auth.py structure and dependencies validated"
  else
    echo "FAIL: $failed checks failed for gcloud_auto_auth.py"
    return 1
  fi
}

test_kubectl_scripts() {
  echo "Testing kubectl helper scripts..."

  local failed=0

  # Test kubectl-diagnose.sh
  local diagnose_path="$DOTFILES_DIR/kubectl-diagnose.sh"
  if [[ -f "$diagnose_path" ]]; then
    # Check for required commands used in script
    if ! grep -q "kubectl\|nc\|curl" "$diagnose_path"; then
      echo "FAIL: kubectl-diagnose.sh missing expected commands"
      ((failed++))
    fi

    # Check for error handling
    if ! grep -q "set -e\|error handling\|timeout" "$diagnose_path"; then
      echo "INFO: kubectl-diagnose.sh may lack robust error handling"
    fi

    echo "PASS: kubectl-diagnose.sh structure validated"
  fi

  # Test kubectl-quick-test.sh
  local quick_test_path="$DOTFILES_DIR/kubectl-quick-test.sh"
  if [[ -f "$quick_test_path" ]]; then
    # Check it uses timeout and kubectl
    if ! grep -q "timeout\|kubectl" "$quick_test_path"; then
      echo "FAIL: kubectl-quick-test.sh missing expected commands"
      ((failed++))
    fi

    echo "PASS: kubectl-quick-test.sh structure validated"
  fi

  # Skip actual kubectl commands in CI
  if [[ -n "$CI" || -n "$GITHUB_ACTIONS" ]]; then
    echo "SKIP: kubectl functionality tests (CI mode)"
  fi

  if [[ $failed -eq 0 ]]; then
    echo "PASS: All kubectl helper scripts validated"
  else
    echo "FAIL: $failed checks failed for kubectl scripts"
    return 1
  fi
}

test_sync_terminal_history() {
  echo "Testing sync-terminal-history.sh..."

  local script_path="$DOTFILES_DIR/sync-terminal-history.sh"
  local failed=0

  # Check for required environment variables
  if ! grep -q "TERMINAL_HISTORY_REMOTE" "$script_path"; then
    echo "FAIL: sync-terminal-history.sh missing TERMINAL_HISTORY_REMOTE check"
    ((failed++))
  fi

  # Check for main functions
  local required_functions=(backup_history sync_history restore_history)
  for func in $required_functions; do
    if ! grep -q "^$func() {" "$script_path"; then
      echo "FAIL: sync-terminal-history.sh missing function: $func"
      ((failed++))
    fi
  done

  # Check for git operations
  if ! grep -q "git init\|git add\|git commit\|git push" "$script_path"; then
    echo "FAIL: sync-terminal-history.sh missing git operations"
    ((failed++))
  fi

  if [[ $failed -eq 0 ]]; then
    echo "PASS: sync-terminal-history.sh structure validated"
  else
    echo "FAIL: $failed checks failed for sync-terminal-history.sh"
    return 1
  fi
}

test_evalcache() {
  echo "Testing evalcache.zsh..."

  local script_path="$DOTFILES_DIR/evalcache.zsh"
  local failed=0

  # Check for the main _evalcache function
  if ! grep -q "^function _evalcache() {" "$script_path"; then
    echo "FAIL: evalcache.zsh missing _evalcache function"
    ((failed++))
  fi

  # Check for cache directory configuration
  if ! grep -q "ZSH_EVALCACHE_DIR" "$script_path"; then
    echo "FAIL: evalcache.zsh missing cache directory configuration"
    ((failed++))
  fi

  # Check for cache clearing function
  if ! grep -q "_evalcache_clear" "$script_path"; then
    echo "FAIL: evalcache.zsh missing cache clearing function"
    ((failed++))
  fi

  # Check the function is defined if zshrc.local was sourced
  if type _evalcache >/dev/null 2>&1; then
    echo "PASS: _evalcache function is defined in current shell"
  else
    echo "INFO: _evalcache function not found (zshrc.local may not have been sourced)"
  fi

  if [[ $failed -eq 0 ]]; then
    echo "PASS: evalcache.zsh structure validated"
  else
    echo "FAIL: $failed checks failed for evalcache.zsh"
    return 1
  fi
}

test_pdbrc() {
  echo "Testing pdbrc.py..."

  local script_path="$DOTFILES_DIR/pdbrc.py"
  local failed=0

  # Check file exists
  if [[ ! -f "$script_path" ]]; then
    echo "FAIL: pdbrc.py not found"
    return 1
  fi

  # Check for pdb import
  if ! grep -q "^import pdb" "$script_path"; then
    echo "FAIL: pdbrc.py missing pdb import"
    ((failed++))
  fi

  # Check for pprint import
  if ! grep -q "from pprint import pformat" "$script_path"; then
    echo "FAIL: pdbrc.py missing pprint import"
    ((failed++))
  fi

  # Check for Config class
  if ! grep -q "class Config(pdb.DefaultConfig):" "$script_path"; then
    echo "FAIL: pdbrc.py missing Config class"
    ((failed++))
  fi

  # Check for sticky mode
  if ! grep -q "sticky_by_default = True" "$script_path"; then
    echo "FAIL: pdbrc.py missing sticky_by_default configuration"
    ((failed++))
  fi

  # Check for custom prompt
  if ! grep -q 'prompt = "(Pdb) "' "$script_path"; then
    echo "FAIL: pdbrc.py missing custom prompt configuration"
    ((failed++))
  fi

  # Check for pretty print setup
  if ! grep -q "pretty_displayhook" "$script_path"; then
    echo "FAIL: pdbrc.py missing pretty displayhook setup"
    ((failed++))
  fi

  # Test syntax if python3 is available
  if command -v python3 >/dev/null 2>&1; then
    if ! python3 -m py_compile "$script_path" 2>/dev/null; then
      echo "FAIL: pdbrc.py has syntax errors"
      ((failed++))
    else
      echo "PASS: pdbrc.py syntax is valid"
    fi
  else
    echo "SKIP: Python3 not available for syntax check (CI mode)"
  fi

  if [[ $failed -eq 0 ]]; then
    echo "PASS: pdbrc.py configuration validated"
  else
    echo "FAIL: $failed checks failed for pdbrc.py"
    return 1
  fi
}

test_dotdot_alias() {
  echo "Testing .. alias..."

  local failed=0

  # Check if the alias is defined
  if ! alias .. >/dev/null 2>&1; then
    echo "FAIL: .. alias not found"
    ((failed++))
  else
    # Check if it points to the right command
    local alias_def=$(alias .. 2>/dev/null)
    if [[ "$alias_def" != *"cd .."* ]]; then
      echo "FAIL: .. alias doesn't point to 'cd ..'"
      ((failed++))
    else
      echo "PASS: .. alias correctly configured"
    fi
  fi

  if [[ $failed -eq 0 ]]; then
    echo "PASS: .. alias validated"
  else
    echo "FAIL: $failed checks failed for .. alias"
    return 1
  fi
}

test_platform_specific_jumping() {
  echo "Testing platform-specific directory jumping..."

  local failed=0

  # Check DOTFILES_OS is set
  if [[ -z "${DOTFILES_OS:-}" ]]; then
    echo "FAIL: DOTFILES_OS is not set"
    ((failed++))
  else
    echo "INFO: DOTFILES_OS = $DOTFILES_OS"
  fi

  # Test macOS jump setup
  if [[ "$DOTFILES_OS" == "macos" ]]; then
    if type jump >/dev/null 2>&1; then
      echo "PASS: jump is available on macOS"
    elif type j >/dev/null 2>&1; then
      echo "PASS: j alias/function is available on macOS"
    elif [[ -n "$CI" || -n "$GITHUB_ACTIONS" ]]; then
      echo "SKIP: jump/j not available (CI mode)"
    else
      echo "FAIL: Neither jump nor j is available on macOS"
      ((failed++))
    fi
  fi

  # Test Linux zoxide setup
  if [[ "$DOTFILES_OS" == "linux" ]]; then
    if command -v zoxide >/dev/null 2>&1; then
      echo "PASS: zoxide is available on Linux"
      # Check for j alias to z
      if alias j >/dev/null 2>&1; then
        local j_alias=$(alias j 2>/dev/null)
        if [[ "$j_alias" == *"z"* ]]; then
          echo "PASS: j aliases to z (zoxide) on Linux"
        fi
      fi
    elif [[ -n "$CI" || -n "$GITHUB_ACTIONS" ]]; then
      echo "SKIP: zoxide not available (CI mode)"
    else
      echo "INFO: zoxide not available on Linux (platform-specific tooling)"
    fi
  fi

  if [[ $failed -eq 0 ]]; then
    echo "PASS: Platform-specific directory jumping validated"
  else
    echo "FAIL: $failed checks failed for directory jumping"
    return 1
  fi
}

# Run all helper scripts tests
run_helper_scripts_tests() {
  echo "=== HELPER SCRIPTS TESTS ==="
  local failed=0

  test_helper_scripts_exist || ((failed++))
  test_gcloud_auto_auth || ((failed++))
  test_kubectl_scripts || ((failed++))
  test_sync_terminal_history || ((failed++))
  test_evalcache || ((failed++))
  test_pdbrc || ((failed++))
  test_dotdot_alias || ((failed++))
  test_platform_specific_jumping || ((failed++))

  if [[ $failed -eq 0 ]]; then
    echo "✓ All helper scripts tests passed"
    return 0
  else
    echo "✗ $failed helper scripts tests failed"
    return 1
  fi
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  run_helper_scripts_tests
fi
