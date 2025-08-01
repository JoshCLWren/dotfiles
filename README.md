# Dotfiles

Personal dotfiles configuration with automated testing and performance optimization.

## Quick Start

```bash
# Clone and source the configuration
git clone <this-repo> ~/dotfiles
echo "source ~/dotfiles/zshrc.local" >> ~/.zshrc
exec zsh

# Run tests to verify everything works
make test
```

## Features

- **Performance Optimized**: Lazy loading for NVM, fnm, jump, and other heavy tools
- **Modular Configuration**: Work-specific configs separated into `work.zsh`
- **Git Utilities**: Advanced tools for handling large files and GitHub rejections
- **Comprehensive Testing**: Full test suite with performance benchmarking
- **Cross-Platform**: Compatible with macOS and Linux

## Testing

### Quick Test Commands

```bash
# Run all tests
make test

# Run specific test types
make test-basic              # Basic functionality
make test-performance        # Performance benchmarks
make test-compatibility      # Environment compatibility
make test-integration        # Real-world scenarios

# Use test runner directly
./test_dotfiles.zsh --help   # See all options
./test_dotfiles.zsh --verbose
./test_dotfiles.zsh --benchmark
```

### Test Types

#### 1. Basic Functionality Tests
- ✅ Essential aliases (status, add, commit, etc.)
- ✅ Git aliases point to correct commands
- ✅ Essential functions exist
- ✅ Git utility functions loaded
- ✅ Lazy loading functions defined

#### 2. Performance Tests
- ⏱️ Shell startup time benchmarking
- 🚀 Lazy loading activation time
- 📊 PATH performance analysis
- 💾 Memory usage monitoring
- 📈 Baseline comparison

#### 3. Compatibility Tests
- 🌍 Cross-platform compatibility
- 📁 Required environment variables
- 🔧 Missing dependency handling
- 📄 File dependency validation
- 🖥️ Terminal capability detection

#### 4. Integration Tests
- 🔄 Git workflow with aliases
- 💼 Work config conditional loading
- 🐳 Docker function integration
- ☸️ Kubernetes tools
- 🛠️ Real repository scenarios

### Test Results

Recent test run results:
- **Basic Functionality**: ✅ All aliases and functions working
- **Performance**: ⚡ ~1.5s startup time, lazy loading active
- **Compatibility**: 🌍 macOS compatible, PATH optimized
- **Integration**: 🔄 Git workflows and work configs operational

## Architecture

### Core Files
- `zshrc.local` - Main configuration with lazy loading
- `work.zsh` - Work-specific aliases and functions  
- `git-large-file-fix` - Git utilities for large file handling
- `CLAUDE.md` - AI assistant context documentation

### Key Features

#### Lazy Loading
```bash
# Functions are defined but not executed until first use
nvm --version    # Loads NVM on first call
fnm env         # Loads fnm on first call
jump shell      # Loads jump on first call
```

#### Modular Work Configuration
```bash
# Work-specific configs automatically loaded if present
[[ -f "$HOME/dotfiles/work.zsh" ]] && source "$HOME/dotfiles/work.zsh"
```

#### Performance Optimizations
- Cached `GOROOT` to avoid repeated `brew` calls
- Lazy loading for heavy Node.js and development tools
- Efficient PATH management with variable substitution

### Git Utilities

Advanced git tools for handling GitHub's file size limitations:

```bash
git_fix_rejected_push           # Scan and remove large files
git_detect_rejected_files       # Parse GitHub error messages
git_paste_fix                  # Fix from clipboard error
```

## Development

### Adding New Tests

1. Create test file in `tests/` directory:
```bash
# tests/my_new_test.zsh
run_my_new_tests() {
  echo "=== MY NEW TESTS ==="
  # Add test functions here
  local failed=0
  test_something || ((failed++))
  
  if [[ $failed -eq 0 ]]; then
    echo "✓ All my new tests passed"
    return 0
  else
    echo "✗ $failed tests failed"
    return 1
  fi
}
```

2. Update test runner function mapping if needed
3. Add Makefile target for convenience

### Performance Monitoring

```bash
# Benchmark current performance
make benchmark

# Watch for performance regressions
make validate-performance

# Continuous testing during development
make watch-tests  # Requires fswatch
```

### CI/CD

GitHub Actions automatically test on:
- macOS (primary platform)
- Linux (compatibility)
- Multiple test scenarios
- Performance regression detection

## Troubleshooting

### Common Issues

**Slow startup time:**
```bash
# Check what's taking time
./test_dotfiles.zsh --test performance

# Profile shell startup
zsh -i -c 'exit' # Should be < 2 seconds
```

**Missing functions:**
```bash
# Run basic functionality test
make test-basic

# Check specific function
type function_name
```

**Work configs not loading:**
```bash
# Verify work.zsh exists and is readable
ls -la ~/dotfiles/work.zsh

# Test conditional loading
./test_dotfiles.zsh --test integration
```

### Getting Help

```bash
# Test runner options
./test_dotfiles.zsh --help

# Makefile targets
make help

# Verbose output for debugging
./test_dotfiles.zsh --verbose
```

## Contributing

1. Make changes to dotfiles
2. Run tests: `make test`
3. Ensure performance is acceptable: `make benchmark`
4. Update tests if adding new functionality
5. Submit pull request

The test suite ensures changes don't break existing functionality and maintain performance standards.