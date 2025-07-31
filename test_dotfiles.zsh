#!/usr/bin/env zsh
# Comprehensive dotfiles test runner
# Usage: ./test_dotfiles.zsh [--verbose] [--test-name]

# Note: Removed set -e to allow proper error handling in test suites

# Configuration
# Use the directory where this script is located
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
TEST_DIR="$DOTFILES_DIR/tests"
LOG_FILE="$DOTFILES_DIR/test_results.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Options
VERBOSE=false
SPECIFIC_TEST=""
BENCHMARK_MODE=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --verbose|-v)
      VERBOSE=true
      shift
      ;;
    --test|-t)
      SPECIFIC_TEST="$2"
      shift 2
      ;;
    --benchmark|-b)
      BENCHMARK_MODE=true
      shift
      ;;
    --help|-h)
      cat <<EOF
Dotfiles Test Runner

Usage: $0 [OPTIONS]

Options:
  --verbose, -v        Enable verbose output
  --test, -t NAME      Run specific test suite
  --benchmark, -b      Run in benchmark mode (performance focus)
  --help, -h          Show this help message

Available test suites:
  basic_functionality  Test aliases and functions
  performance         Benchmark startup time and lazy loading
  compatibility       Test environment compatibility
  integration         Test real-world usage scenarios
  all                 Run all test suites (default)

Examples:
  $0                           # Run all tests
  $0 --verbose                 # Run all tests with verbose output
  $0 --test performance        # Run only performance tests
  $0 --benchmark              # Focus on performance benchmarking
EOF
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# Logging functions
log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log_verbose() {
  if [[ "$VERBOSE" == "true" ]]; then
    echo "[DEBUG] $*" | tee -a "$LOG_FILE"
  else
    echo "[DEBUG] $*" >> "$LOG_FILE"
  fi
}

print_header() {
  local title="$1"
  local width=60
  local padding=$(( (width - ${#title}) / 2 ))
  
  echo
  printf "${CYAN}%*s${NC}\n" $width | tr ' ' '='
  printf "${CYAN}%*s%s%*s${NC}\n" $padding "" "$title" $padding ""
  printf "${CYAN}%*s${NC}\n" $width | tr ' ' '='
  echo
}

print_section() {
  local section="$1"
  echo
  printf "${YELLOW}>>> %s${NC}\n" "$section"
}

print_success() {
  printf "${GREEN}✓ %s${NC}\n" "$1"
}

print_failure() {
  printf "${RED}✗ %s${NC}\n" "$1"
}

print_warning() {
  printf "${YELLOW}⚠ %s${NC}\n" "$1"
}

print_info() {
  printf "${BLUE}ℹ %s${NC}\n" "$1"
}

# Pre-flight checks
run_preflight_checks() {
  print_section "Pre-flight Checks"
  
  # Check if we're in the right directory
  if [[ ! -f "$DOTFILES_DIR/zshrc.local" ]]; then
    print_failure "dotfiles directory not found or invalid: $DOTFILES_DIR"
    exit 1
  fi
  
  # Check if test directory exists
  if [[ ! -d "$TEST_DIR" ]]; then
    print_failure "Test directory not found: $TEST_DIR"
    exit 1
  fi
  
  # Check if we're running in zsh
  if [[ -z "$ZSH_VERSION" ]]; then
    print_failure "Tests must be run in zsh"
    exit 1
  fi
  
  # Initialize log file
  echo "=== Dotfiles Test Run Started at $(date) ===" > "$LOG_FILE"
  
  print_success "Pre-flight checks passed"
  log_verbose "Dotfiles directory: $DOTFILES_DIR"
  log_verbose "Test directory: $TEST_DIR"
  log_verbose "Zsh version: $ZSH_VERSION"
  log_verbose "Platform: $(uname -s)"
}

# Source dotfiles for testing
prepare_test_environment() {
  print_section "Preparing Test Environment"
  
  if [[ -n "$CI" || -n "$GITHUB_ACTIONS" ]]; then
    log_verbose "CI environment detected, using best-effort config loading"
    
    # In CI, just try to source what we can without failing the entire test run
    # Comment out problematic lines that are known to fail in CI
    local temp_file=$(mktemp)
    sed -e 's|^source /opt/homebrew|# CI-SKIP: source /opt/homebrew|g' \
        -e 's|^export DOCKER_HOST=.*colima.*|# CI-SKIP: export DOCKER_HOST (colima not available)|g' \
        "$DOTFILES_DIR/zshrc.local" > "$temp_file"
    
    # Source with best effort - don't fail if some things don't work
    if source "$temp_file" 2>/dev/null; then
      print_success "Sourced zshrc.local (CI mode)"
    else
      print_warning "Partial config loading in CI - some features unavailable"
    fi
    
    # Always ensure git utilities are available
    [[ -f "$DOTFILES_DIR/git-large-file-fix" ]] && source "$DOTFILES_DIR/git-large-file-fix" 2>/dev/null
    
    rm -f "$temp_file"
  else
    # Normal local testing - full functionality expected
    if source "$DOTFILES_DIR/zshrc.local" 2>/dev/null; then
      print_success "Successfully sourced zshrc.local"
    else
      print_failure "Failed to source zshrc.local"
      exit 1
    fi
  fi
  
  log_verbose "Test environment prepared"
}

# Run a specific test suite
run_test_suite() {
  local test_name="$1"
  local test_file="$TEST_DIR/${test_name}.zsh"
  
  if [[ ! -f "$test_file" ]]; then
    print_failure "Test file not found: $test_file"
    return 1
  fi
  
  print_section "Running $test_name tests"
  log "Starting $test_name tests"
  
  local start_time=$(date +%s)
  
  # Source and run the test
  if source "$test_file"; then
    # Determine correct function name based on test type
    local func_name
    case "$test_name" in
      "basic_functionality") func_name="run_basic_tests" ;;
      "performance") func_name="run_performance_tests" ;;
      "compatibility") func_name="run_compatibility_tests" ;;
      "integration") func_name="run_integration_tests" ;;
      *) func_name="run_${test_name}_tests" ;;
    esac
    
    # Capture both output and exit code properly
    local test_output
    test_output=$(eval "$func_name" 2>&1)
    local test_exit_code=$?
    echo "$test_output" | tee -a "$LOG_FILE"
    
    if [[ $test_exit_code -eq 0 ]]; then
      local end_time=$(date +%s)
      local duration=$((end_time - start_time))
      print_success "$test_name tests completed in ${duration}s"
      log "$test_name tests PASSED in ${duration}s"
      return 0
    else
      local end_time=$(date +%s)
      local duration=$((end_time - start_time))
      print_failure "$test_name tests failed in ${duration}s"
      log "$test_name tests FAILED in ${duration}s"
      return 1
    fi
  else
    print_failure "Failed to source test file: $test_file"
    return 1
  fi
}

# Generate system information report
generate_system_report() {
  print_section "System Information"
  
  cat <<EOF | tee -a "$LOG_FILE"
System Information:
  OS: $(uname -s) $(uname -r)
  Architecture: $(uname -m)
  Shell: $SHELL (zsh version: $ZSH_VERSION)
  User: $USER
  Home: $HOME
  Terminal: $TERM
  Locale: $(locale | grep LANG | head -1)

Environment:
  PATH entries: $(echo $PATH | tr ':' '\n' | wc -l)
  GOPATH: ${GOPATH:-"not set"}
  GOROOT: ${GOROOT:-"not set"}
  NVM_DIR: ${NVM_DIR:-"not set"}
  DOCKER_HOST: ${DOCKER_HOST:-"not set"}

Dotfiles:
  Directory: $DOTFILES_DIR
  Config file: $(ls -la "$DOTFILES_DIR/zshrc.local" 2>/dev/null || echo "not found")
  Work config: $(ls -la "$DOTFILES_DIR/work.zsh" 2>/dev/null || echo "not found")
  Git utilities: $(ls -la "$DOTFILES_DIR/git-large-file-fix" 2>/dev/null || echo "not found")
EOF
}

# Performance benchmark mode
run_benchmark_mode() {
  print_header "DOTFILES PERFORMANCE BENCHMARK"
  
  generate_system_report
  
  # Focus on performance tests
  local benchmark_tests=(performance)
  local failed=0
  
  for test in $benchmark_tests; do
    if ! run_test_suite "$test"; then
      ((failed++))
    fi
  done
  
  # Additional benchmark-specific tests
  print_section "Extended Performance Analysis"
  
  # Multiple startup time measurements
  print_info "Running extended startup time analysis..."
  for i in {1..10}; do
    local time_output=$(time (zsh -i -c 'exit' 2>/dev/null) 2>&1)
    local real_time=$(echo "$time_output" | grep real | awk '{print $2}')
    log_verbose "Startup $i: $real_time"
  done
  
  return $failed
}

# Main test runner
run_all_tests() {
  local test_suites=(
    "basic_functionality"
    "performance"
    "compatibility"
    "integration"
  )
  
  local passed=0
  local failed=0
  local warnings=0
  
  for test in $test_suites; do
    if run_test_suite "$test"; then
      ((passed++))
    else
      ((failed++))
    fi
  done
  
  return $failed
}

# Results summary
print_results_summary() {
  local exit_code=$1
  
  print_section "Test Results Summary"
  
  if [[ $exit_code -eq 0 ]]; then
    print_success "All tests passed! ✨"
    log "TEST RUN COMPLETED SUCCESSFULLY"
  else
    print_failure "Some tests failed ($exit_code test suites)"
    log "TEST RUN COMPLETED WITH FAILURES: $exit_code"
  fi
  
  print_info "Detailed results logged to: $LOG_FILE"
  
  # Show recent log entries
  if [[ "$VERBOSE" == "true" ]]; then
    echo
    echo "Recent log entries:"
    tail -20 "$LOG_FILE"
  fi
}

# Cleanup function
cleanup() {
  log_verbose "Cleaning up test artifacts..."
  # Clean up any temporary files created during tests
  find /tmp -name "test_dotfiles_*" -type d -mmin -60 2>/dev/null | xargs rm -rf
}

# Signal handlers
trap cleanup EXIT
trap 'echo "Test interrupted"; exit 130' INT TERM

# Main execution
main() {
  print_header "DOTFILES AUTOMATED TEST SUITE"
  
  run_preflight_checks
  prepare_test_environment
  generate_system_report
  
  local exit_code=0
  
  if [[ "$BENCHMARK_MODE" == "true" ]]; then
    run_benchmark_mode
    exit_code=$?
  elif [[ -n "$SPECIFIC_TEST" ]]; then
    if [[ "$SPECIFIC_TEST" == "all" ]]; then
      run_all_tests
      exit_code=$?
    else
      run_test_suite "$SPECIFIC_TEST"
      exit_code=$?
    fi
  else
    run_all_tests
    exit_code=$?
  fi
  
  print_results_summary $exit_code
  
  exit $exit_code
}

# Run main function
main "$@"