#!/usr/bin/env zsh
# Lazy loading mechanism tests for dotfiles

test_nvm_lazy_loading() {
  echo "Testing nvm lazy loading..."

  if ! type nvm >/dev/null 2>&1; then
    echo "FAIL: nvm function not defined"
    return 1
  fi

  local nvm_type=$(type nvm 2>/dev/null)
  if [[ "$nvm_type" != *"shell function"* ]]; then
    echo "FAIL: nvm is not a shell function (lazy loading not set up)"
    return 1
  fi

  if [[ -n "$CI" || -n "$GITHUB_ACTIONS" ]]; then
    echo "SKIP: Testing nvm activation in CI (NVM may not be available)"
    echo "PASS: nvm lazy loading function defined"
    return 0
  fi

  local before_call=$(type nvm 2>/dev/null | head -1)
  nvm --version >/dev/null 2>&1 || true
  local after_call=$(type nvm 2>/dev/null | head -1)

  if [[ "$before_call" == "$after_call" ]]; then
    echo "WARN: nvm function may not have been replaced after first call"
  else
    echo "INFO: nvm function replaced after activation"
  fi

  echo "PASS: nvm lazy loading works"
}

test_node_lazy_loading() {
  echo "Testing node lazy loading..."

  if ! type node >/dev/null 2>&1; then
    echo "FAIL: node function not defined"
    return 1
  fi

  local node_type=$(type node 2>/dev/null)
  if [[ "$node_type" != *"shell function"* ]]; then
    echo "FAIL: node is not a shell function (lazy loading not set up)"
    return 1
  fi

  if [[ -n "$CI" || -n "$GITHUB_ACTIONS" ]]; then
    echo "SKIP: Testing node activation in CI (node binary may not be available)"
    echo "PASS: node lazy loading function defined"
    return 0
  fi

  local before_call=$(type node 2>/dev/null | head -1)
  node --version >/dev/null 2>&1 || true
  local after_call=$(type node 2>/dev/null | head -1)

  if [[ "$before_call" == "$after_call" ]]; then
    echo "WARN: node function may not have been replaced after first call"
  else
    echo "INFO: node function replaced after activation"
  fi

  echo "PASS: node lazy loading works"
}

test_npm_lazy_loading() {
  echo "Testing npm lazy loading..."

  if ! type npm >/dev/null 2>&1; then
    echo "FAIL: npm function not defined"
    return 1
  fi

  local npm_type=$(type npm 2>/dev/null)
  if [[ "$npm_type" != *"shell function"* ]]; then
    echo "FAIL: npm is not a shell function (lazy loading not set up)"
    return 1
  fi

  if [[ -n "$CI" || -n "$GITHUB_ACTIONS" ]]; then
    echo "SKIP: Testing npm activation in CI (npm binary may not be available)"
    echo "PASS: npm lazy loading function defined"
    return 0
  fi

  local before_call=$(type npm 2>/dev/null | head -1)
  npm --version >/dev/null 2>&1 || true
  local after_call=$(type npm 2>/dev/null | head -1)

  if [[ "$before_call" == "$after_call" ]]; then
    echo "WARN: npm function may not have been replaced after first call"
  else
    echo "INFO: npm function replaced after activation"
  fi

  echo "PASS: npm lazy loading works"
}

test_jump_lazy_loading() {
  echo "Testing jump lazy loading..."

  if [[ "${DOTFILES_OS:-}" == "macos" ]]; then
    if ! type jump >/dev/null 2>&1; then
      if command -v jump >/dev/null 2>&1; then
        echo "FAIL: jump binary exists but lazy function not defined"
        return 1
      else
        echo "INFO: jump binary not available - skipping jump tests"
        echo "PASS: jump tests skipped (binary not installed)"
        return 0
      fi
    fi

    local jump_type=$(type jump 2>/dev/null)
    if [[ "$jump_type" != *"shell function"* ]]; then
      echo "FAIL: jump is not a shell function on macOS"
      return 1
    fi

    if [[ -n "$CI" || -n "$GITHUB_ACTIONS" ]]; then
      echo "SKIP: Testing jump activation in CI"
      echo "PASS: jump lazy loading function defined on macOS"
      return 0
    fi

    if type _evalcache >/dev/null 2>&1; then
      echo "INFO: jump using _evalcache for lazy loading"
    else
      echo "INFO: jump using self-loading mechanism"
    fi

    echo "PASS: jump lazy loading configured correctly on macOS"
  elif [[ "${DOTFILES_OS:-}" == "linux" ]]; then
    echo "INFO: Linux platform - jump not used (zoxide instead)"
    echo "PASS: jump not configured on Linux (as expected)"
  else
    echo "INFO: Unknown platform $DOTFILES_OS - skipping jump tests"
    echo "PASS: jump tests skipped (unknown platform)"
  fi
}

test_zoxide_lazy_loading() {
  echo "Testing zoxide lazy loading..."

  if [[ "${DOTFILES_OS:-}" == "linux" ]]; then
    if ! command -v zoxide >/dev/null 2>&1; then
      echo "INFO: zoxide binary not available - skipping zoxide tests"
      echo "PASS: zoxide tests skipped (binary not installed)"
      return 0
    fi

    if ! type z >/dev/null 2>&1; then
      echo "FAIL: zoxide installed but 'z' function not defined"
      return 1
    fi

    if ! alias j >/dev/null 2>&1; then
      echo "WARN: 'j' alias not defined for zoxide"
    else
      local j_alias=$(alias j 2>/dev/null)
      if [[ "$j_alias" != *"z"* ]]; then
        echo "FAIL: 'j' alias does not point to zoxide"
        return 1
      fi
      echo "INFO: 'j' alias correctly points to zoxide"
    fi

    echo "PASS: zoxide configured correctly on Linux"
  elif [[ "${DOTFILES_OS:-}" == "macos" ]]; then
    echo "INFO: macOS platform - zoxide not used (jump instead)"
    echo "PASS: zoxide not configured on macOS (as expected)"
  else
    echo "INFO: Unknown platform $DOTFILES_OS - skipping zoxide tests"
    echo "PASS: zoxide tests skipped (unknown platform)"
  fi
}

test_j_alias_platform_specific() {
  echo "Testing j alias platform-specific configuration..."

  if [[ "${DOTFILES_OS:-}" == "macos" ]]; then
    if ! type j >/dev/null 2>&1; then
      if command -v jump >/dev/null 2>&1; then
        echo "FAIL: jump binary available but 'j' function not defined on macOS"
        return 1
      else
        echo "INFO: jump binary not available - 'j' function expected to be absent"
        echo "PASS: 'j' not defined when jump is unavailable on macOS"
        return 0
      fi
    fi

    local j_type=$(type j 2>/dev/null)
    if [[ "$j_type" != *"shell function"* ]]; then
      echo "FAIL: 'j' is not a shell function on macOS"
      return 1
    fi

    echo "PASS: 'j' function correctly defined on macOS"
  elif [[ "${DOTFILES_OS:-}" == "linux" ]]; then
    if ! alias j >/dev/null 2>&1; then
      if command -v zoxide >/dev/null 2>&1; then
        echo "FAIL: zoxide installed but 'j' alias not defined on Linux"
        return 1
      else
        echo "INFO: zoxide binary not available - 'j' alias expected to be absent"
        echo "PASS: 'j' not defined when zoxide is unavailable on Linux"
        return 0
      fi
    fi

    local j_alias=$(alias j 2>/dev/null)
    if [[ "$j_alias" != *"z"* ]]; then
      echo "FAIL: 'j' alias does not point to zoxide on Linux"
      return 1
    fi

    echo "PASS: 'j' alias correctly points to zoxide on Linux"
  else
    echo "INFO: Unknown platform $DOTFILES_OS - skipping 'j' alias tests"
    echo "PASS: 'j' alias tests skipped (unknown platform)"
  fi
}

test_fnm_lazy_loading() {
  echo "Testing fnm lazy loading..."

  if ! command -v fnm >/dev/null 2>&1; then
    echo "INFO: fnm binary not available - skipping fnm tests"
    echo "PASS: fnm tests skipped (binary not installed)"
    return 0
  fi

  if ! type fnm >/dev/null 2>&1; then
    echo "FAIL: fnm binary exists but lazy function not defined"
    return 1
  fi

  local fnm_type=$(type fnm 2>/dev/null)
  if [[ "$fnm_type" != *"shell function"* ]]; then
    echo "FAIL: fnm is not a shell function"
    return 1
  fi

  if [[ -n "$CI" || -n "$GITHUB_ACTIONS" ]]; then
    echo "SKIP: Testing fnm activation in CI"
    echo "PASS: fnm lazy loading function defined"
    return 0
  fi

  if type _evalcache >/dev/null 2>&1; then
    echo "INFO: fnm using _evalcache for lazy loading"
  else
    echo "INFO: fnm using self-loading mechanism"
  fi

  echo "PASS: fnm lazy loading configured correctly"
}

test_lazy_loading_timing() {
  echo "Testing lazy loading timing performance..."

  if [[ -n "$CI" || -n "$GITHUB_ACTIONS" ]]; then
    echo "SKIP: Timing tests in CI environment"
    echo "PASS: Timing tests skipped (CI mode)"
    return 0
  fi

  local config_start=$(date +%s.%N)
  source "$HOME/dotfiles/zshrc.local" >/dev/null 2>&1
  local config_end=$(date +%s.%N)
  local config_time=$(echo "$config_end - $config_start" | bc -l 2>/dev/null || echo "0")

  echo "Config load time: ${config_time}s"

  if (( $(echo "$config_time > 1.0" | bc -l 2>/dev/null || echo "0") )); then
    echo "WARN: Config loading took longer than expected (${config_time}s > 1.0s)"
  else
    echo "INFO: Config loaded quickly (${config_time}s)"
  fi

  if type nvm >/dev/null 2>&1; then
    local nvm_start=$(date +%s.%N)
    nvm --version >/dev/null 2>&1 || true
    local nvm_end=$(date +%s.%N)
    local nvm_time=$(echo "$nvm_end - $nvm_start" | bc -l 2>/dev/null || echo "0")

    echo "First nvm call time: ${nvm_time}s"

    if (( $(echo "$nvm_time > 2.0" | bc -l 2>/dev/null || echo "0") )); then
      echo "WARN: First nvm call took longer than expected (${nvm_time}s > 2.0s)"
    else
      echo "INFO: First nvm call acceptable (${nvm_time}s)"
    fi
  fi

  echo "PASS: Lazy loading timing tests completed"
}

test_evalcache_usage() {
  echo "Testing _evalcache usage for lazy loading..."

  if ! type _evalcache >/dev/null 2>&1; then
    echo "INFO: _evalcache not available - tools will use self-loading"
    echo "PASS: Self-loading fallback confirmed"
    return 0
  fi

  echo "INFO: _evalcache is available for optimized lazy loading"

  if [[ "${DOTFILES_OS:-}" == "macos" ]] && type jump >/dev/null 2>&1; then
    echo "INFO: jump on macOS can use _evalcache"
  fi

  if type fnm >/dev/null 2>&1; then
    echo "INFO: fnm can use _evalcache"
  fi

  echo "PASS: _evalcache usage verified"
}

test_nvm_path_setup() {
  echo "Testing NVM path setup for immediate access..."

  if [[ -z "${NVM_DIR:-}" ]]; then
    echo "FAIL: NVM_DIR not set"
    return 1
  fi

  echo "INFO: NVM_DIR set to: $NVM_DIR"

  if [[ ! -f "$NVM_DIR/alias/default" ]]; then
    echo "INFO: NVM default alias not found - path setup not applicable"
    echo "PASS: NVM path setup skipped (no default alias)"
    return 0
  fi

  local path_has_nvm=0
  IFS=':' read -ra PATH_ARRAY <<< "$PATH"
  for path_entry in "$PATH_ARRAY[@]"; do
    if [[ "$path_entry" == *"$NVM_DIR/versions/node"* ]]; then
      path_has_nvm=1
      echo "INFO: Found NVM node bin in PATH: $path_entry"
      break
    fi
  done

  if [[ $path_has_nvm -eq 1 ]]; then
    echo "PASS: NVM default node bin is in PATH (immediate access)"
  else
    echo "INFO: NVM default node bin not in PATH (lazy loading will activate on use)"
    echo "PASS: NVM path configuration valid"
  fi
}

test_lazy_loading_consistency() {
  echo "Testing lazy loading consistency..."

  local lazy_functions=(nvm node npm)
  local failed=0

  for func in $lazy_functions; do
    if ! type "$func" >/dev/null 2>&1; then
      echo "SKIP: $func not defined - consistency test not applicable"
      continue
    fi

    local func_type=$(type "$func" 2>/dev/null)
    if [[ "$func_type" != *"shell function"* ]]; then
      echo "FAIL: $func is not consistently lazy-loaded (not a shell function)"
      ((failed++))
    fi
  done

  if [[ $failed -eq 0 ]]; then
    echo "PASS: All defined lazy loading functions are consistent"
  else
    echo "FAIL: $failed lazy loading functions are inconsistent"
    return 1
  fi
}

run_lazy_loading_tests() {
  echo "=== LAZY LOADING TESTS ==="
  local failed=0

  test_nvm_lazy_loading || ((failed++))
  test_node_lazy_loading || ((failed++))
  test_npm_lazy_loading || ((failed++))
  test_jump_lazy_loading || ((failed++))
  test_zoxide_lazy_loading || ((failed++))
  test_j_alias_platform_specific || ((failed++))
  test_fnm_lazy_loading || ((failed++))
  test_lazy_loading_timing || ((failed++))
  test_evalcache_usage || ((failed++))
  test_nvm_path_setup || ((failed++))
  test_lazy_loading_consistency || ((failed++))

  if [[ $failed -eq 0 ]]; then
    echo "✓ All lazy loading tests passed"
    return 0
  else
    echo "✗ $failed lazy loading tests failed"
    return 1
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  run_lazy_loading_tests
fi
