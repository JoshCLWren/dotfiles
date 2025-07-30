#!/usr/bin/env zsh
# Integration and alias/function validation tests

test_git_aliases_functionality() {
  echo "Testing git aliases functionality..."
  
  # Create a temporary git repo for testing
  local temp_repo=$(mktemp -d)
  cd "$temp_repo"
  
  git init >/dev/null 2>&1
  git config user.email "test@example.com"
  git config user.name "Test User"
  
  # Test basic git aliases
  echo "test content" > test.txt
  
  # Test 'add' alias (git add .)
  add 2>/dev/null
  if git diff --cached --name-only | grep -q "test.txt"; then
    echo "PASS: 'add' alias works (git add .)"
  else
    echo "FAIL: 'add' alias not working"
    cd / && rm -rf "$temp_repo"
    return 1
  fi
  
  # Test 'status' alias
  local status_output=$(status 2>/dev/null)
  if [[ "$status_output" == *"Changes to be committed"* ]]; then
    echo "PASS: 'status' alias works (git status)"
  else
    echo "FAIL: 'status' alias not working"
    cd / && rm -rf "$temp_repo"
    return 1
  fi
  
  # Test 'commit' alias
  commit -m "test commit" >/dev/null 2>&1
  if git log --oneline | grep -q "test commit"; then
    echo "PASS: 'commit' alias works (git commit)"
  else
    echo "FAIL: 'commit' alias not working"
    cd / && rm -rf "$temp_repo"
    return 1
  fi
  
  # Test 'gl' alias (git log)
  local log_output=$(gl 2>/dev/null)
  if [[ "$log_output" == *"test commit"* ]]; then
    echo "PASS: 'gl' alias works (git log --oneline --decorate --graph)"
  else
    echo "FAIL: 'gl' alias not working"
    cd / && rm -rf "$temp_repo"
    return 1
  fi
  
  cd / && rm -rf "$temp_repo"
  echo "PASS: Git aliases integration test complete"
}

test_work_aliases_conditional_loading() {
  echo "Testing work aliases conditional loading..."
  
  # Test with work.zsh present
  if [[ -f "$HOME/dotfiles/work.zsh" ]]; then
    if which mikey >/dev/null 2>&1; then
      echo "PASS: Work aliases loaded when work.zsh exists"
    else
      echo "FAIL: Work aliases not loaded despite work.zsh existing"
      return 1
    fi
    
    # Test work-specific aliases point to correct commands
    local mikey_alias=$(alias mikey 2>/dev/null)
    if [[ "$mikey_alias" == *"mikeybuild"* ]]; then
      echo "PASS: Work alias 'mikey' correctly configured"
    else
      echo "FAIL: Work alias 'mikey' incorrectly configured"
      return 1
    fi
  else
    echo "INFO: work.zsh not present, testing graceful handling"
    if ! which mikey >/dev/null 2>&1; then
      echo "PASS: Work aliases not loaded when work.zsh missing (graceful)"
    else
      echo "FAIL: Work aliases present without work.zsh file"
      return 1
    fi
  fi
}

test_lazy_loading_integration() {
  echo "Testing lazy loading integration..."
  
  # Test NVM lazy loading
  if type nvm >/dev/null 2>&1; then
    # Should be a function initially
    local nvm_type=$(type nvm 2>/dev/null)
    if [[ "$nvm_type" == *"shell function"* ]]; then
      echo "PASS: NVM is lazy loaded (function defined)"
      
      # Test that calling it actually loads NVM
      local nvm_version=$(nvm --version 2>/dev/null)
      if [[ -n "$nvm_version" ]]; then
        echo "PASS: NVM lazy loading activates correctly (version: $nvm_version)"
      else
        echo "WARN: NVM lazy loading defined but activation failed"
      fi
    else
      echo "INFO: NVM is not lazy loaded (directly available)"
    fi
  else
    echo "INFO: NVM not available for lazy loading test"
  fi
  
  # Test Node lazy loading
  if type node >/dev/null 2>&1; then
    local node_type=$(type node 2>/dev/null)
    if [[ "$node_type" == *"shell function"* ]]; then
      echo "PASS: Node is lazy loaded (function defined)"
    else
      echo "INFO: Node is directly available (not lazy loaded)"
    fi
  fi
}

test_git_utilities_integration() {
  echo "Testing git utilities integration..."
  
  # Create a test repo with a large file scenario
  local temp_repo=$(mktemp -d)
  cd "$temp_repo"
  
  git init >/dev/null 2>&1
  git config user.email "test@example.com"
  git config user.name "Test User"
  
  # Create a moderately sized file (not actually large, just for testing)
  echo "This is test content for git utilities" > test_file.txt
  git add test_file.txt
  git commit -m "Add test file" >/dev/null 2>&1
  
  # Test that git_fix_rejected_push function exists and can analyze
  if type git_fix_rejected_push >/dev/null 2>&1; then
    echo "PASS: git_fix_rejected_push function available"
    
    # Test git_detect_rejected_files with mock input
    if type git_detect_rejected_files >/dev/null 2>&1; then
      echo "PASS: git_detect_rejected_files function available"
    else
      echo "FAIL: git_detect_rejected_files function missing"
      cd / && rm -rf "$temp_repo"
      return 1
    fi
  else
    echo "FAIL: git_fix_rejected_push function missing"
    cd / && rm -rf "$temp_repo"
    return 1
  fi
  
  cd / && rm -rf "$temp_repo"
  echo "PASS: Git utilities integration test complete"
}

test_docker_functions_integration() {
  echo "Testing Docker functions integration..."
  
  # Test fix_colima_docker function exists
  if type fix_colima_docker >/dev/null 2>&1; then
    echo "PASS: fix_colima_docker function available"
    
    # Test DOCKER_HOST is set
    if [[ -n "$DOCKER_HOST" ]]; then
      echo "PASS: DOCKER_HOST environment variable set ($DOCKER_HOST)"
    else
      echo "FAIL: DOCKER_HOST environment variable not set"
      return 1
    fi
  else
    echo "FAIL: fix_colima_docker function missing"
    return 1
  fi
}

test_kubernetes_integration() {
  echo "Testing Kubernetes integration..."
  
  # Test kubectl alias
  if which k >/dev/null 2>&1; then
    local k_alias=$(alias k 2>/dev/null)
    if [[ "$k_alias" == *"kubectl"* ]]; then
      echo "PASS: 'k' alias points to kubectl"
    else
      echo "FAIL: 'k' alias incorrectly configured"
      return 1
    fi
  else
    echo "FAIL: 'k' alias not found"
    return 1
  fi
  
  # Note: We don't test actual kubectl functionality since it requires cluster access
  echo "PASS: Kubernetes aliases configured"
}

test_path_integration() {
  echo "Testing PATH integration..."
  
  # Test that common tools can be found
  local tools=(git zsh ls cat)
  local failed=0
  
  for tool in $tools; do
    if ! which $tool >/dev/null 2>&1; then
      echo "FAIL: Essential tool '$tool' not found in PATH"
      ((failed++))
    fi
  done
  
  if [[ $failed -eq 0 ]]; then
    echo "PASS: All essential tools found in PATH"
  else
    echo "FAIL: $failed essential tools missing from PATH"
    return 1
  fi
  
  # Test custom PATH entries
  local custom_paths=(
    "$HOME/.cargo/bin"
    "$HOME/bin"
  )
  
  for path_entry in $custom_paths; do
    if [[ "$PATH" == *"$path_entry"* ]]; then
      echo "PASS: Custom path '$path_entry' in PATH"
    else
      echo "WARN: Custom path '$path_entry' not in PATH"
    fi
  done
}

test_environment_integration() {
  echo "Testing environment variable integration..."
  
  # Test Go environment
  if [[ -n "$GOPATH" && -n "$GOROOT" ]]; then
    echo "PASS: Go environment variables set (GOPATH: $GOPATH, GOROOT: $GOROOT)"
  else
    echo "FAIL: Go environment variables not properly set"
    return 1
  fi
  
  # Test other environment variables
  local env_vars=(USE_GKE_GCLOUD_AUTH_PLUGIN LEFTHOOK DOCKER_HOST)
  for var in $env_vars; do
    if [[ -n "${(P)var}" ]]; then
      echo "PASS: Environment variable $var set"
    else
      echo "WARN: Environment variable $var not set"
    fi
  done
}

# Run all integration tests
run_integration_tests() {
  echo "=== INTEGRATION TESTS ==="
  local failed=0
  
  test_git_aliases_functionality || ((failed++))
  test_work_aliases_conditional_loading || ((failed++))
  test_lazy_loading_integration || ((failed++))
  test_git_utilities_integration || ((failed++))
  test_docker_functions_integration || ((failed++))
  test_kubernetes_integration || ((failed++))
  test_path_integration || ((failed++))
  test_environment_integration || ((failed++))
  
  if [[ $failed -eq 0 ]]; then
    echo "✓ All integration tests passed"
    return 0
  else
    echo "✗ $failed integration tests failed"
    return 1
  fi
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  run_integration_tests
fi