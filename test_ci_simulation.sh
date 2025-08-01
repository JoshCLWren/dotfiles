#!/bin/bash
# Local simulation of GitHub Actions macOS environment

echo "=== Simulating GitHub Actions macOS Environment ==="

# Create a clean environment similar to GitHub Actions
export CI=true
export GITHUB_ACTIONS=true
export RUNNER_OS=macOS
export USER=runner
export HOME=/tmp/ci_test_home

# Unset variables that would typically not be available in CI
unset GOPATH
unset NVM_DIR
unset DOCKER_HOST

# Create a minimal home directory
mkdir -p "$HOME"

# Run the test in this simulated environment
echo "Running dotfiles tests in simulated CI environment..."
echo "Environment variables:"
echo "  CI: $CI"
echo "  GITHUB_ACTIONS: $GITHUB_ACTIONS"
echo "  USER: $USER"
echo "  HOME: $HOME"
echo "  GOPATH: ${GOPATH:-"(unset)"}"
echo "  NVM_DIR: ${NVM_DIR:-"(unset)"}"
echo "  DOCKER_HOST: ${DOCKER_HOST:-"(unset)"}"
echo ""

cd "$(dirname "$0")"
./test_dotfiles.zsh --verbose

exit_code=$?
echo ""
echo "=== CI Simulation Complete ==="
echo "Exit code: $exit_code"

# Cleanup
rm -rf "$HOME"

exit $exit_code