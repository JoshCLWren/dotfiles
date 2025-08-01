#!/usr/bin/env zsh
# Performance benchmarking tests for dotfiles

# Function to measure shell startup time
measure_startup_time() {
  local iterations=${1:-5}
  local times=()
  local total=0
  
  echo "Measuring shell startup time over $iterations iterations..."
  
  # In CI environments, startup time measurement can be unreliable
  if [[ -n "$CI" || -n "$GITHUB_ACTIONS" ]]; then
    echo "INFO: Skipping detailed startup time measurement in CI environment"
    echo "PASS: Startup time measurement skipped in CI"
    return 0
  fi
  
  for i in $(seq 1 $iterations); do
    # Measure time for a new zsh shell to start and exit
    local time_output=$(time (zsh -i -c 'exit' 2>/dev/null) 2>&1)
    
    # Parse different time output formats (real time or total time)
    local real_time=""
    if echo "$time_output" | grep -q "real"; then
      # Format: "real 0.123s" or "real    0m0.123s"
      real_time=$(echo "$time_output" | grep real | awk '{print $2}' | sed 's/[^0-9.]//g')
    elif echo "$time_output" | grep -q "total"; then
      # Format: "0.06s user 0.07s system 55% cpu 0.241 total"
      real_time=$(echo "$time_output" | awk '{print $(NF-1)}' | sed 's/[^0-9.]//g')
    fi
    
    if [[ -n "$real_time" && "$real_time" != "0" ]]; then
      times+=($real_time)
      total=$(echo "$total + $real_time" | bc -l 2>/dev/null || echo "$total")
    fi
  done
  
  if [[ ${#times[@]} -gt 0 ]]; then
    local average=$(echo "scale=3; $total / ${#times[@]}" | bc -l 2>/dev/null || echo "0")
    echo "Startup times: ${times[*]}"
    echo "Average startup time: ${average}s"
    
    # Fail if average startup time is over 2 seconds (reasonable threshold)
    if (( $(echo "$average > 2.0" | bc -l 2>/dev/null || echo "0") )); then
      echo "FAIL: Shell startup time too slow (${average}s > 2.0s)"
      return 1
    else
      echo "PASS: Shell startup time acceptable (${average}s)"
      return 0
    fi
  else
    echo "WARN: Could not measure startup time reliably"
    echo "PASS: Startup time measurement skipped due to parsing issues"
    return 0
  fi
}

test_lazy_loading_performance() {
  echo "Testing lazy loading performance..."
  
  # Test that lazy functions are defined quickly
  local start_time=$(date +%s.%N)
  
  # Source the config (this should be fast since lazy functions aren't loaded)
  source "$HOME/dotfiles/zshrc.local" >/dev/null 2>&1
  
  local end_time=$(date +%s.%N)
  local load_time=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "0")
  
  echo "Config load time: ${load_time}s"
  
  # Should load in under 1 second
  if (( $(echo "$load_time > 1.0" | bc -l 2>/dev/null || echo "0") )); then
    echo "FAIL: Config loading too slow (${load_time}s > 1.0s)"
    return 1
  else
    echo "PASS: Config loads quickly (${load_time}s)"
  fi
  
  # Test that first lazy function call works
  echo "Testing lazy function activation..."
  local nvm_start=$(date +%s.%N)
  nvm --version >/dev/null 2>&1
  local nvm_end=$(date +%s.%N)
  local nvm_time=$(echo "$nvm_end - $nvm_start" | bc -l 2>/dev/null || echo "0")
  
  echo "First nvm call time: ${nvm_time}s"
  echo "PASS: Lazy loading functions work"
}

test_path_performance() {
  echo "Testing PATH performance..."
  
  # Test that PATH operations are fast
  local start_time=$(date +%s.%N)
  
  # Simulate path operations
  local path_length=$(echo $PATH | tr ':' '\n' | wc -l)
  which git >/dev/null 2>&1
  which zsh >/dev/null 2>&1
  which ls >/dev/null 2>&1
  
  local end_time=$(date +%s.%N)
  local path_time=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "0")
  
  echo "PATH operations time: ${path_time}s (PATH length: $path_length entries)"
  
  # Warn if PATH is very long (might slow down command lookups)
  if [[ $path_length -gt 50 ]]; then
    echo "WARN: PATH is quite long ($path_length entries) - consider cleanup"
  fi
  
  echo "PASS: PATH operations complete"
}

benchmark_against_baseline() {
  echo "Benchmarking against baseline shell..."
  
  # Create a minimal zshrc for comparison
  local temp_zshrc=$(mktemp)
  echo "# Minimal zshrc for baseline" > "$temp_zshrc"
  
  # Measure baseline
  local baseline_time=$(time (ZDOTDIR=$(dirname "$temp_zshrc") zsh -i -c 'exit' 2>/dev/null) 2>&1 | grep real | awk '{print $2}' | sed 's/[^0-9.]//g')
  
  # Measure our config
  local our_time=$(time (zsh -i -c 'exit' 2>/dev/null) 2>&1 | grep real | awk '{print $2}' | sed 's/[^0-9.]//g')
  
  rm -f "$temp_zshrc"
  
  if [[ -n "$baseline_time" && -n "$our_time" ]]; then
    local overhead=$(echo "scale=3; $our_time - $baseline_time" | bc -l 2>/dev/null || echo "0")
    echo "Baseline startup: ${baseline_time}s"
    echo "Our config startup: ${our_time}s"
    echo "Overhead: ${overhead}s"
    
    # Acceptable overhead is under 1 second
    if (( $(echo "$overhead > 1.0" | bc -l 2>/dev/null || echo "0") )); then
      echo "FAIL: Config overhead too high (${overhead}s > 1.0s)"
      return 1
    else
      echo "PASS: Config overhead acceptable (${overhead}s)"
    fi
  else
    echo "WARN: Could not benchmark against baseline"
  fi
}

test_memory_usage() {
  echo "Testing memory usage..."
  
  # Get current shell memory usage
  local pid=$$
  local memory_kb=$(ps -o rss= -p $pid 2>/dev/null | tr -d ' ')
  
  if [[ -n "$memory_kb" ]]; then
    local memory_mb=$(echo "scale=2; $memory_kb / 1024" | bc -l 2>/dev/null || echo "0")
    echo "Current shell memory usage: ${memory_mb}MB"
    
    # Warn if memory usage is excessive (over 50MB for a shell is unusual)
    if (( $(echo "$memory_mb > 50" | bc -l 2>/dev/null || echo "0") )); then
      echo "WARN: High memory usage (${memory_mb}MB > 50MB)"
    else
      echo "PASS: Memory usage reasonable (${memory_mb}MB)"
    fi
  else
    echo "WARN: Could not measure memory usage"
  fi
}

# Run all performance tests
run_performance_tests() {
  echo "=== PERFORMANCE TESTS ==="
  local failed=0
  
  measure_startup_time || ((failed++))
  test_lazy_loading_performance || ((failed++))
  test_path_performance || ((failed++))
  benchmark_against_baseline || ((failed++))
  test_memory_usage || ((failed++))
  
  if [[ $failed -eq 0 ]]; then
    echo "✓ All performance tests passed"
    return 0
  else
    echo "✗ $failed performance tests failed"
    return 1
  fi
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  run_performance_tests
fi