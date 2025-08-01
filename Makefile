# Dotfiles Makefile for testing and maintenance

.PHONY: test test-verbose test-performance test-compatibility test-integration test-basic help install lint clean

# Default target
help:
	@echo "Dotfiles Test Suite"
	@echo ""
	@echo "Available targets:"
	@echo "  test                 Run all tests"
	@echo "  test-verbose         Run all tests with verbose output"
	@echo "  test-performance     Run only performance tests"
	@echo "  test-compatibility   Run only compatibility tests"
	@echo "  test-integration     Run only integration tests"
	@echo "  test-basic          Run only basic functionality tests"
	@echo "  benchmark           Run performance benchmarks"
	@echo "  install             Install/update dotfiles"
	@echo "  lint                Check shell script syntax"
	@echo "  clean               Clean up test artifacts"
	@echo "  help                Show this help message"

# Test targets
test:
	@echo "Running full test suite..."
	./test_dotfiles.zsh

test-verbose:
	@echo "Running full test suite (verbose)..."
	./test_dotfiles.zsh --verbose

test-performance:
	@echo "Running performance tests..."
	./test_dotfiles.zsh --test performance

test-compatibility:
	@echo "Running compatibility tests..."
	./test_dotfiles.zsh --test compatibility

test-integration:
	@echo "Running integration tests..."
	./test_dotfiles.zsh --test integration

test-basic:
	@echo "Running basic functionality tests..."
	./test_dotfiles.zsh --test basic_functionality

benchmark:
	@echo "Running performance benchmarks..."
	./test_dotfiles.zsh --benchmark

# Installation and maintenance
install:
	@echo "Installing/updating dotfiles..."
	@if [ -f ~/.zshrc ]; then \
		echo "Backing up existing ~/.zshrc to ~/.zshrc.backup"; \
		cp ~/.zshrc ~/.zshrc.backup; \
	fi
	@echo "source $(PWD)/zshrc.local" >> ~/.zshrc
	@echo "Dotfiles installed. Restart your shell or run 'exec zsh'"

lint:
	@echo "Checking shell script syntax..."
	@for file in *.zsh test_dotfiles.zsh tests/*.zsh; do \
		if [ -f "$$file" ]; then \
			echo "Checking $$file..."; \
			zsh -n "$$file" || exit 1; \
		fi; \
	done
	@echo "All shell scripts pass syntax check"

clean:
	@echo "Cleaning up test artifacts..."
	@rm -f test_results.log
	@find . -name "*.tmp" -delete
	@find /tmp -name "test_dotfiles_*" -type d -mmin +60 2>/dev/null | xargs rm -rf || true
	@echo "Cleanup complete"

# Development helpers
watch-tests:
	@echo "Watching for changes and running tests..."
	@which fswatch >/dev/null || (echo "fswatch not installed. Install with: brew install fswatch" && exit 1)
	fswatch -o . | xargs -n1 -I{} make test

quick-test:
	@echo "Running quick test (basic functionality only)..."
	./test_dotfiles.zsh --test basic_functionality

# Validation targets
validate-performance:
	@echo "Validating performance requirements..."
	@./test_dotfiles.zsh --test performance | grep -q "PASS.*startup time acceptable" || \
		(echo "Performance validation failed" && exit 1)
	@echo "Performance validation passed"

validate-compatibility:
	@echo "Validating cross-platform compatibility..."
	@./test_dotfiles.zsh --test compatibility | grep -q "All compatibility tests passed" || \
		(echo "Compatibility validation failed" && exit 1)
	@echo "Compatibility validation passed"

# CI/CD helpers
ci-test:
	@echo "Running CI test suite..."
	./test_dotfiles.zsh --verbose > ci_test_results.log 2>&1 || \
		(echo "CI tests failed. Check ci_test_results.log for details" && exit 1)
	@echo "CI tests passed"

# Documentation
test-docs:
	@echo "Available test commands:"
	@echo ""
	@echo "Basic Usage:"
	@echo "  make test              # Run all tests"
	@echo "  make test-basic        # Quick basic functionality test"
	@echo "  make benchmark         # Performance benchmarking"
	@echo ""
	@echo "Development:"
	@echo "  make lint              # Check syntax"
	@echo "  make clean             # Clean up"
	@echo "  make watch-tests       # Watch and test on changes"
	@echo ""
	@echo "For detailed options, run: ./test_dotfiles.zsh --help"