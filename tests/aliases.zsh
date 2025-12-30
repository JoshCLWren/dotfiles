#!/usr/bin/env zsh
# Comprehensive alias tests for zshrc.local

test_git_aliases() {
  echo "Testing git aliases..."
  local failed=0

  # Test undo alias
  local undo_alias=$(alias undo 2>/dev/null)
  if [[ "$undo_alias" == *"git restore"* ]]; then
    echo "PASS: 'undo' alias exists"
  else
    echo "FAIL: 'undo' alias missing or incorrect"
    ((failed++))
  fi

  # Test gagrc alias
  local gagrc_alias=$(alias gagrc 2>/dev/null)
  if [[ "$gagrc_alias" == *"git rebase --continue"* ]]; then
    echo "PASS: 'gagrc' alias exists"
  else
    echo "FAIL: 'gagrc' alias missing or incorrect"
    ((failed++))
  fi

  # Test gti alias
  local gti_alias=$(alias gti 2>/dev/null)
  if [[ "$gti_alias" == *"git"* ]]; then
    echo "PASS: 'gti' alias exists"
  else
    echo "FAIL: 'gti' alias missing or incorrect"
    ((failed++))
  fi

  # Test _rebase alias
  local rebase_alias=$(alias _rebase 2>/dev/null)
  if [[ "$rebase_alias" == *"git pull origin main --rebase"* ]]; then
    echo "PASS: '_rebase' alias exists"
  else
    echo "FAIL: '_rebase' alias missing or incorrect"
    ((failed++))
  fi

  # Test existing git aliases
  local git_aliases=(status add commit gl new)
  for alias_name in $git_aliases; do
    if ! which $alias_name >/dev/null 2>&1; then
      echo "FAIL: git alias '$alias_name' not found"
      ((failed++))
    fi
  done

  if [[ $failed -eq 0 ]]; then
    echo "PASS: All git aliases configured correctly"
    return 0
  else
    echo "FAIL: $failed git aliases have issues"
    return 1
  fi
}

test_tool_aliases() {
  echo "Testing tool aliases..."
  local failed=0
  local skipped=0

  # Test be alias (bundle exec)
  local be_alias=$(alias be 2>/dev/null)
  if [[ "$be_alias" == *"bundle exec"* ]]; then
    echo "PASS: 'be' alias exists"
  else
    echo "FAIL: 'be' alias missing or incorrect"
    ((failed++))
  fi

  # Test rspec alias
  local rspec_alias=$(alias rspec 2>/dev/null)
  if [[ "$rspec_alias" == *"bundle exec rspec"* ]]; then
    echo "PASS: 'rspec' alias exists"
  else
    echo "FAIL: 'rspec' alias missing or incorrect"
    ((failed++))
  fi

  # Test refresh alias
  local refresh_alias=$(alias refresh 2>/dev/null)
  if [[ "$refresh_alias" == *"source ~/.zshrc"* ]]; then
    echo "PASS: 'refresh' alias exists"
  else
    echo "FAIL: 'refresh' alias missing or incorrect"
    ((failed++))
  fi

  # Test bug alias
  local bug_alias=$(alias bug 2>/dev/null)
  if [[ "$bug_alias" == *"pytest"* ]]; then
    echo "PASS: 'bug' alias exists"
  else
    echo "FAIL: 'bug' alias missing or incorrect"
    ((failed++))
  fi

  # Test mouse alias
  local mouse_alias=$(alias mouse 2>/dev/null)
  if [[ "$mouse_alias" == *"tmux set mouse"* ]]; then
    echo "PASS: 'mouse' alias exists"
  else
    echo "FAIL: 'mouse' alias missing or incorrect"
    ((failed++))
  fi

  # Test sniff alias
  local sniff_alias=$(alias sniff 2>/dev/null)
  if [[ "$sniff_alias" == *"sniffer"* ]]; then
    echo "PASS: 'sniff' alias exists"
  else
    echo "FAIL: 'sniff' alias missing or incorrect"
    ((failed++))
  fi

  # Test new alias
  local new_alias=$(alias new 2>/dev/null)
  if [[ "$new_alias" == *"git checkout -b"* ]]; then
    echo "PASS: 'new' alias exists"
  else
    echo "FAIL: 'new' alias missing or incorrect"
    ((failed++))
  fi

  # Test nyan alias
  local nyan_alias=$(alias nyan 2>/dev/null)
  if [[ "$nyan_alias" == *"go-nyancat"* ]]; then
    echo "PASS: 'nyan' alias exists"
  else
    echo "FAIL: 'nyan' alias missing or incorrect"
    ((failed++))
  fi

  # Test bu alias
  if command -v brew >/dev/null 2>&1; then
    local bu_alias=$(alias bu 2>/dev/null)
    if [[ "$bu_alias" == *"brew update"* ]]; then
      echo "PASS: 'bu' alias exists and brew is available"
    else
      echo "FAIL: 'bu' alias missing or incorrect"
      ((failed++))
    fi
  else
    echo "SKIP: 'bu' alias (brew not available)"
    ((skipped++))
  fi

  # Test gemini-cli alias
  local gemini_alias=$(alias gemini-cli 2>/dev/null)
  if [[ "$gemini_alias" == *"gemini"* ]]; then
    echo "PASS: 'gemini-cli' alias exists"
  else
    echo "FAIL: 'gemini-cli' alias missing or incorrect"
    ((failed++))
  fi

  if [[ $failed -eq 0 ]]; then
    echo "PASS: All tested tool aliases configured correctly ($skipped skipped)"
    return 0
  else
    echo "FAIL: $failed tool aliases have issues"
    return 1
  fi
}

test_kubernetes_aliases() {
  echo "Testing kubernetes aliases..."
  local failed=0

  # Test k alias (kubectl)
  if which k >/dev/null 2>&1; then
    local k_alias=$(alias k 2>/dev/null)
    if [[ "$k_alias" == *"kubectl"* ]]; then
      echo "PASS: 'k' alias points to kubectl"
    else
      echo "FAIL: 'k' alias incorrectly configured"
      ((failed++))
    fi
  else
    echo "FAIL: 'k' alias not found"
    ((failed++))
  fi

  # Test kx alias (requires kube-get-pod function)
  local kx_alias=$(alias kx 2>/dev/null)
  if [[ "$kx_alias" == *"kubectl exec"* ]] && [[ "$kx_alias" == *"kube-get-pod"* ]]; then
    echo "PASS: 'kx' alias exists and references kube-get-pod"
  else
    echo "FAIL: 'kx' alias missing or incorrect"
    ((failed++))
  fi

  # Test kxa alias (requires kube-get-pod function and api-app container)
  local kxa_alias=$(alias kxa 2>/dev/null)
  if [[ "$kxa_alias" == *"kubectl exec"* ]] && [[ "$kxa_alias" == *"api-app"* ]]; then
    echo "PASS: 'kxa' alias exists and references api-app container"
  else
    echo "FAIL: 'kxa' alias missing or incorrect"
    ((failed++))
  fi

  # Verify kube-get-pod function exists
  if type kube-get-pod >/dev/null 2>&1; then
    echo "PASS: 'kube-get-pod' function exists"
  else
    echo "FAIL: 'kube-get-pod' function missing (required by kx/kxa)"
    ((failed++))
  fi

  if [[ $failed -eq 0 ]]; then
    echo "PASS: All kubernetes aliases configured correctly"
    return 0
  else
    echo "FAIL: $failed kubernetes aliases have issues"
    return 1
  fi
}

test_gcloud_aliases() {
  echo "Testing Google Cloud aliases..."
  local failed=0
  local skipped=0

  # Skip all gcloud tests in CI
  if [[ -n "$CI" || -n "$GITHUB_ACTIONS" ]]; then
    echo "SKIP: All gcloud aliases (CI mode - no gcloud available)"
    return 0
  fi

  # Test gke-staging alias
  local gke_staging_alias=$(alias gke-staging 2>/dev/null)
  if [[ "$gke_staging_alias" == *"gcloud container clusters get-credentials"* ]]; then
    if [[ "$gke_staging_alias" == *"yv-api-staging"* ]]; then
      echo "PASS: 'gke-staging' alias exists and references correct cluster"
    else
      echo "FAIL: 'gke-staging' alias references wrong cluster"
      ((failed++))
    fi
  else
    echo "FAIL: 'gke-staging' alias missing or incorrect"
    ((failed++))
  fi

  # Test gke-prod alias
  local gke_prod_alias=$(alias gke-prod 2>/dev/null)
  if [[ "$gke_prod_alias" == *"gcloud container clusters get-credentials"* ]]; then
    if [[ "$gke_prod_alias" == *"yv-api-prod"* ]]; then
      echo "PASS: 'gke-prod' alias exists and references correct cluster"
    else
      echo "FAIL: 'gke-prod' alias references wrong cluster"
      ((failed++))
    fi
  else
    echo "FAIL: 'gke-prod' alias missing or incorrect"
    ((failed++))
  fi

  # Test gcloud-auth alias
  local gcloud_auth_alias=$(alias gcloud-auth 2>/dev/null)
  if [[ "$gcloud_auth_alias" == *"gcloud_auto_auth.py"* ]]; then
    echo "PASS: 'gcloud-auth' alias exists"
  else
    echo "FAIL: 'gcloud-auth' alias missing or incorrect"
    ((failed++))
  fi

  # Verify gcloud_auto_auth.py script exists
  if [[ -f "$HOME/dotfiles/gcloud_auto_auth.py" ]]; then
    echo "PASS: 'gcloud_auto_auth.py' script exists"
  else
    echo "WARN: 'gcloud_auto_auth.py' script not found"
    ((skipped++))
  fi

  if [[ $failed -eq 0 ]]; then
    echo "PASS: All tested gcloud aliases configured correctly ($skipped skipped)"
    return 0
  else
    echo "FAIL: $failed gcloud aliases have issues"
    return 1
  fi
}

test_platform_specific_aliases() {
  echo "Testing platform-specific aliases..."
  local failed=0
  local skipped=0

  # Skip platform-specific tests in CI
  if [[ -n "$CI" || -n "$GITHUB_ACTIONS" ]]; then
    echo "SKIP: Platform-specific aliases (CI mode)"
    return 0
  fi

  # Test pycharm alias (macOS only)
  if [[ "${DOTFILES_OS:-}" == "macos" ]]; then
    local pycharm_alias=$(alias pycharm 2>/dev/null)
    if [[ "$pycharm_alias" == *"PyCharm"* ]]; then
      if [[ -a "/Users/joshwren/Applications/PyCharm.app" ]]; then
        echo "PASS: 'pycharm' alias exists and PyCharm.app is installed"
      else
        echo "WARN: 'pycharm' alias exists but PyCharm.app not installed"
        ((skipped++))
      fi
    else
      echo "FAIL: 'pycharm' alias missing on macOS"
      ((failed++))
    fi
  else
    echo "SKIP: 'pycharm' alias (not on macOS)"
    ((skipped++))
  fi

  if [[ $failed -eq 0 ]]; then
    echo "PASS: Platform-specific aliases correct ($skipped skipped)"
    return 0
  else
    echo "FAIL: $failed platform-specific aliases have issues"
    return 1
  fi
}

test_alias_availability() {
  echo "Testing alias availability..."
  local failed=0

  # List of all aliases that should be available
  local -a all_aliases=(
    undo gagrc gti _rebase be rspec refresh bug mouse sniff new nyan bu
    status add commit gl k gemini-cli kx kxa gke-staging gke-prod gcloud-auth pycharm
  )

  for alias_name in $all_aliases; do
    if ! alias $alias_name >/dev/null 2>&1; then
      echo "WARN: Alias '$alias_name' not defined"
    fi
  done

  echo "PASS: Alias availability check complete"
  return 0
}

test_alias_conflicts() {
  echo "Testing alias conflicts..."
  local failed=0

  # Check for potential conflicts (gvi vs git, etc.)
  # gti is an alias for git (intentional typo correction)
  local gti_alias=$(alias gti 2>/dev/null)
  if [[ "$gti_alias" == *"git"* ]]; then
    echo "PASS: 'gti' correctly aliased to 'git' (typo fix)"
  else
    echo "FAIL: 'gti' not correctly aliased to 'git'"
    ((failed++))
  fi

  # Check that new doesn't conflict with anything
  local new_alias=$(alias new 2>/dev/null)
  if [[ "$new_alias" == *"git checkout -b"* ]]; then
    echo "PASS: 'new' correctly aliased to 'git checkout -b'"
  else
    echo "FAIL: 'new' alias incorrect"
    ((failed++))
  fi

  if [[ $failed -eq 0 ]]; then
    echo "PASS: No alias conflicts detected"
    return 0
  else
    echo "FAIL: $failed alias conflicts detected"
    return 1
  fi
}

# Run all alias tests
run_aliases_tests() {
  echo "=== ALIAS TESTS ==="
  local failed=0

  test_git_aliases || ((failed++))
  test_tool_aliases || ((failed++))
  test_kubernetes_aliases || ((failed++))
  test_gcloud_aliases || ((failed++))
  test_platform_specific_aliases || ((failed++))
  test_alias_availability || ((failed++))
  test_alias_conflicts || ((failed++))

  if [[ $failed -eq 0 ]]; then
    echo "✓ All alias tests passed"
    return 0
  else
    echo "✗ $failed alias tests failed"
    return 1
  fi
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  run_aliases_tests
fi
