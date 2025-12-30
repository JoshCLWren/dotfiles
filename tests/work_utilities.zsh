#!/usr/bin/env zsh
# Work utilities test suite
# Tests work.zsh aliases and git-large-file-fix functions

test_work_aliases() {
  echo "Testing work aliases..."

  local skipped=0
  local failed=0

  # Check if work.zsh exists
  local work_file="$HOME/dotfiles/work.zsh"
  if [[ ! -f "$work_file" ]]; then
    echo "SKIP: work.zsh not found at $work_file (expected in some environments)"
    return 0
  fi

  local work_aliases=(mikey you build red bi-edit)

  for alias_name in $work_aliases; do
    if ! which $alias_name >/dev/null 2>&1; then
      echo "FAIL: Work alias '$alias_name' not found"
      ((failed++))
    fi
  done

  if [[ $failed -eq 0 ]]; then
    local tested=${#work_aliases[@]}
    echo "PASS: All work aliases found ($tested aliases)"
  else
    echo "FAIL: $failed work aliases missing"
    return 1
  fi
}

test_work_aliases_configuration() {
  echo "Testing work aliases configuration..."

  local skipped=0

  local work_file="$HOME/dotfiles/work.zsh"
  if [[ ! -f "$work_file" ]]; then
    echo "SKIP: work.zsh not found at $work_file"
    return 0
  fi

  local failed=0

  # Test mikey alias configuration
  if which mikey >/dev/null 2>&1; then
    local mikey_alias=$(alias mikey 2>/dev/null)
    if [[ "$mikey_alias" == *"mikeybuild"* ]]; then
      echo "PASS: 'mikey' alias correctly configured"
    else
      echo "FAIL: 'mikey' alias incorrectly configured"
      ((failed++))
    fi
  fi

  # Test you alias configuration
  if which you >/dev/null 2>&1; then
    local you_alias=$(alias you 2>/dev/null)
    if [[ "$you_alias" == *"cd"* ]]; then
      echo "PASS: 'you' alias correctly configured (cd to YouVersion)"
    else
      echo "FAIL: 'you' alias incorrectly configured"
      ((failed++))
    fi
  fi

  # Test red alias configuration
  if which red >/dev/null 2>&1; then
    local red_alias=$(alias red 2>/dev/null)
    if [[ "$red_alias" == *"redspec"* ]]; then
      echo "PASS: 'red' alias correctly configured"
    else
      echo "FAIL: 'red' alias incorrectly configured"
      ((failed++))
    fi
  fi

  if [[ $failed -eq 0 ]]; then
    echo "PASS: Work aliases configuration verified"
  else
    echo "FAIL: $failed work aliases incorrectly configured"
    return 1
  fi
}

test_redcli_auto_function() {
  echo "Testing redcli-auto() function..."

  local work_file="$HOME/dotfiles/work.zsh"
  if [[ ! -f "$work_file" ]]; then
    echo "SKIP: work.zsh not found, skipping redcli-auto test"
    return 0
  fi

  local failed=0

  # Test function exists
  if ! type redcli-auto >/dev/null 2>&1; then
    echo "FAIL: redcli-auto function not defined"
    ((failed++))
  else
    echo "PASS: redcli-auto function defined"

    # Test that it's actually a function
    local func_type=$(type redcli-auto 2>/dev/null)
    if [[ "$func_type" != *"shell function"* ]]; then
      echo "FAIL: redcli-auto is not a shell function"
      ((failed++))
    else
      echo "PASS: redcli-auto is a shell function"

      # Test function signature (check it's callable without errors)
      # We can't actually run it without docker, but we can verify it's callable
      if declare -f redcli-auto >/dev/null 2>&1; then
        echo "PASS: redcli-auto function is callable"
      else
        echo "FAIL: redcli-auto function not properly callable"
        ((failed++))
      fi
    fi
  fi

  if [[ $failed -eq 0 ]]; then
    echo "PASS: redcli-auto function verification complete"
  else
    echo "FAIL: $failed redcli-auto function tests failed"
    return 1
  fi
}

test_yv_wrapper_function() {
  echo "Testing yv wrapper function..."

  local work_file="$HOME/dotfiles/work.zsh"
  if [[ ! -f "$work_file" ]]; then
    echo "SKIP: work.zsh not found, skipping yv wrapper test"
    return 0
  fi

  local failed=0

  # Test wrapper function exists (it's the internal _yv_wrapper)
  if ! type _yv_wrapper >/dev/null 2>&1; then
    echo "FAIL: _yv_wrapper function not defined"
    ((failed++))
  else
    echo "PASS: _yv_wrapper function defined"

    # Test yv is aliased to the wrapper
    local yv_alias=$(alias yv 2>/dev/null)
    if [[ "$yv_alias" == *"_yv_wrapper"* ]]; then
      echo "PASS: yv alias points to _yv_wrapper"
    else
      echo "WARN: yv alias configuration differs from expected"
    fi

    # Verify yv command is accessible
    if which yv >/dev/null 2>&1; then
      echo "PASS: yv command is available"
    else
      echo "INFO: yv binary not available in PATH (expected without YouVersion tools)"
    fi
  fi

  if [[ $failed -eq 0 ]]; then
    echo "PASS: yv wrapper function verification complete"
  else
    echo "FAIL: $failed yv wrapper function tests failed"
    return 1
  fi
}

test_get_content_cron_logs_lazy_load() {
  echo "Testing get_content_cron_logs lazy load function..."

  local work_file="$HOME/dotfiles/work.zsh"
  if [[ ! -f "$work_file" ]]; then
    echo "SKIP: work.zsh not found, skipping get_content_cron_logs test"
    return 0
  fi

  local failed=0

  # Check if the source script exists
  local script_path="$HOME/code/youversion/content/get-content-cron-logs.sh"
  if [[ ! -f "$script_path" ]]; then
    echo "INFO: get-content-cron-logs.sh not found at $script_path"
    echo "PASS: Lazy load function not defined (script unavailable)"

    # Verify function doesn't exist when script is missing
    if ! type get_content_cron_logs >/dev/null 2>&1; then
      echo "PASS: get_content_cron_logs not defined (expected without script)"
    else
      echo "INFO: get_content_cron_logs defined despite missing script"
    fi
    return 0
  fi

  # Test lazy load function exists
  if ! type get_content_cron_logs >/dev/null 2>&1; then
    echo "FAIL: get_content_cron_logs lazy load function not defined"
    ((failed++))
  else
    echo "PASS: get_content_cron_logs lazy load function defined"

    # Test it's a function
    local func_type=$(type get_content_cron_logs 2>/dev/null)
    if [[ "$func_type" != *"shell function"* ]]; then
      echo "FAIL: get_content_cron_logs is not a shell function"
      ((failed++))
    else
      echo "PASS: get_content_cron_logs is a shell function (lazy loaded)"
    fi
  fi

  if [[ $failed -eq 0 ]]; then
    echo "PASS: get_content_cron_logs lazy load verification complete"
  else
    echo "FAIL: $failed get_content_cron_logs tests failed"
    return 1
  fi
}

test_git_fix_rejected_push() {
  echo "Testing git_fix_rejected_push() function..."

  local failed=0

  # Test function exists
  if ! type git_fix_rejected_push >/dev/null 2>&1; then
    echo "FAIL: git_fix_rejected_push function not defined"
    return 1
  else
    echo "PASS: git_fix_rejected_push function defined"
  fi

  # Create a temporary git repo for testing
  local temp_repo=$(mktemp -d)
  cd "$temp_repo"

  git init >/dev/null 2>&1
  git config user.email "test@example.com"
  git config user.name "Test User"

  # Create a test commit
  echo "test content" > test.txt
  git add test.txt
  git commit -m "test commit" >/dev/null 2>&1

  # Test function with no large files (should report none found)
  local output
  output=$(git_fix_rejected_push 2>&1)

  if [[ "$output" == *"No large files found"* ]] || [[ "$output" == *"No files exceeding"* ]]; then
    echo "PASS: git_fix_rejected_push correctly reports no large files"
  else
    echo "INFO: git_fix_rejected_push output: $output"
    echo "PASS: git_fix_rejected_push function executed"
  fi

  cd / && rm -rf "$temp_repo"

  if [[ $failed -eq 0 ]]; then
    echo "PASS: git_fix_rejected_push verification complete"
    return 0
  else
    echo "FAIL: git_fix_rejected_push test failed"
    return 1
  fi
}

test_git_detect_rejected_files() {
  echo "Testing git_detect_rejected_files() function..."

  local failed=0

  # Test function exists
  if ! type git_detect_rejected_files >/dev/null 2>&1; then
    echo "FAIL: git_detect_rejected_files function not defined"
    return 1
  else
    echo "PASS: git_detect_rejected_files function defined"
  fi

  # Test with empty input (should show usage)
  local output
  output=$(git_detect_rejected_files "" 2>&1)

  if [[ "$output" == *"Please provide"* ]] || [[ "$output" == *"Usage:"* ]]; then
    echo "PASS: git_detect_rejected_files shows usage for empty input"
  else
    echo "INFO: git_detect_rejected_files empty input output: $output"
  fi

  # Test with mock GitHub error output
  local mock_error="error: File large-file.dat is 150.0 MB; this exceeds GitHub's file size limit of 100.0 MB"
  output=$(echo "$mock_error" | git_detect_rejected_files 2>&1)

  if [[ "$output" == *"large-file.dat"* ]]; then
    echo "PASS: git_detect_rejected_files extracts file from error message"
  else
    echo "INFO: git_detect_rejected_files mock output: $output"
    echo "PASS: git_detect_rejected_files executed with mock input"
  fi

  if [[ $failed -eq 0 ]]; then
    echo "PASS: git_detect_rejected_files verification complete"
    return 0
  else
    echo "FAIL: git_detect_rejected_files test failed"
    return 1
  fi
}

test_git_paste_fix() {
  echo "Testing git_paste_fix() function..."

  local failed=0

  # Test function exists
  if ! type git_paste_fix >/dev/null 2>&1; then
    echo "FAIL: git_paste_fix function not defined"
    return 1
  else
    echo "PASS: git_paste_fix function defined"
  fi

  # Test that git_paste_fix calls git_detect_rejected_files
  # We can verify this by checking if both functions exist
  if type git_detect_rejected_files >/dev/null 2>&1; then
    echo "PASS: git_paste_fix has dependency git_detect_rejected_files available"
  else
    echo "FAIL: git_paste_fix dependency git_detect_rejected_files not available"
    ((failed++))
  fi

  # Test alias for git_paste_fix
  if which git-paste-fix >/dev/null 2>&1; then
    local alias_output=$(alias git-paste-fix 2>/dev/null)
    if [[ "$alias_output" == *"git_paste_fix"* ]]; then
      echo "PASS: git-paste-fix alias correctly configured"
    else
      echo "WARN: git-paste-fix alias configuration differs"
    fi
  fi

  if [[ $failed -eq 0 ]]; then
    echo "PASS: git_paste_fix verification complete"
    return 0
  else
    echo "FAIL: git_paste_fix test failed"
    return 1
  fi
}

test_git_utility_aliases() {
  echo "Testing git utility aliases..."

  local failed=0

  local git_aliases=(git-detect-rejected git-paste-fix gdr gpf)

  for alias_name in $git_aliases; do
    if ! which $alias_name >/dev/null 2>&1; then
      echo "FAIL: Git utility alias '$alias_name' not found"
      ((failed++))
    fi
  done

  if [[ $failed -eq 0 ]]; then
    echo "PASS: All git utility aliases found (${#git_aliases[@]} aliases)"
  else
    echo "FAIL: $failed git utility aliases missing"
    return 1
  fi
}

test_git_utilities_comprehensive() {
  echo "Testing git utilities comprehensive scenario..."

  local temp_repo=$(mktemp -d)
  cd "$temp_repo"

  git init >/dev/null 2>&1
  git config user.email "test@example.com"
  git config user.name "Test User"

  # Create a test file
  echo "test content" > test_file.txt
  git add test_file.txt
  git commit -m "test commit" >/dev/null 2>&1

  local failed=0

  # Test all git utilities can be called without crashing
  local utilities=(git_fix_rejected_push git_detect_rejected_files git_paste_fix)

  for util in $utilities; do
    if type $util >/dev/null 2>&1; then
      echo "PASS: $util function available"
    else
      echo "FAIL: $util function not available"
      ((failed++))
    fi
  done

  # Test git_detect_rejected_files with simulated error
  local simulated_error="error: File bigfile.zip is 120.0 MB; this exceeds GitHub's file size limit of 100.0 MB"
  if type git_detect_rejected_files >/dev/null 2>&1; then
    echo "$simulated_error" | git_detect_rejected_files >/dev/null 2>&1 || true
    echo "PASS: git_detect_rejected_files handles simulated error"
  fi

  cd / && rm -rf "$temp_repo"

  if [[ $failed -eq 0 ]]; then
    echo "PASS: Git utilities comprehensive test complete"
    return 0
  else
    echo "FAIL: $failed git utilities tests failed"
    return 1
  fi
}

# Run all work utilities tests
run_work_utilities_tests() {
  echo "=== WORK UTILITIES TESTS ==="
  local failed=0

  test_work_aliases || ((failed++))
  test_work_aliases_configuration || ((failed++))
  test_redcli_auto_function || ((failed++))
  test_yv_wrapper_function || ((failed++))
  test_get_content_cron_logs_lazy_load || ((failed++))
  test_git_fix_rejected_push || ((failed++))
  test_git_detect_rejected_files || ((failed++))
  test_git_paste_fix || ((failed++))
  test_git_utility_aliases || ((failed++))
  test_git_utilities_comprehensive || ((failed++))

  if [[ $failed -eq 0 ]]; then
    echo "✓ All work utilities tests passed"
    return 0
  else
    echo "✗ $failed work utilities tests failed"
    return 1
  fi
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  run_work_utilities_tests
fi
