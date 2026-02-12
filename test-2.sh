#!/bin/bash

#############################################################################
# TEST SCRIPT FOR PORTAINER CE INSTALLER
# Tests the 2.sh installer script functionality
#
# This script validates:
# - Script syntax
# - Function definitions
# - Error handling
# - DNF command compatibility
#############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

TEST_PASSED=0
TEST_FAILED=0

print_test() {
    echo -e "${BLUE}[TEST] $1${NC}"
}

print_pass() {
    echo -e "${GREEN}  ✅ PASS: $1${NC}"
    ((TEST_PASSED++))
}

print_fail() {
    echo -e "${RED}  ❌ FAIL: $1${NC}"
    ((TEST_FAILED++))
}

print_info() {
    echo -e "${YELLOW}  ℹ️  INFO: $1${NC}"
}

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║           PORTAINER INSTALLER TEST SUITE                      ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# Test 1: Script exists and is executable
print_test "Checking if 2.sh exists and is executable..."
if [[ -f "2.sh" && -x "2.sh" ]]; then
    print_pass "Script exists and is executable"
else
    print_fail "Script does not exist or is not executable"
fi

# Test 2: Script has valid bash syntax
print_test "Validating bash syntax..."
if bash -n 2.sh 2>/dev/null; then
    print_pass "Bash syntax is valid"
else
    print_fail "Bash syntax errors detected"
fi

# Test 3: Check for required functions
print_test "Checking for required functions..."
required_functions=(
    "print_header"
    "print_phase"
    "print_step"
    "print_success"
    "print_error"
    "check_root"
    "check_fedora_version"
    "remove_old_docker"
    "install_dependencies"
    "add_docker_repository"
    "install_docker"
    "start_docker"
    "verify_docker"
    "install_portainer"
    "configure_firewall"
    "add_user_to_docker_group"
    "print_summary"
    "main"
)

for func in "${required_functions[@]}"; do
    if grep -q "^${func}()" 2.sh; then
        print_pass "Function '$func' defined"
    else
        print_fail "Function '$func' not found"
    fi
done

# Test 4: Check for error handling
print_test "Checking error handling mechanisms..."
if grep -q "set -e" 2.sh; then
    print_pass "Exit on error is enabled (set -e)"
else
    print_fail "Exit on error is not enabled"
fi

if grep -q "set -u" 2.sh; then
    print_pass "Exit on undefined variable is enabled (set -u)"
else
    print_fail "Exit on undefined variable is not enabled"
fi

if grep -q "trap.*cleanup_on_error" 2.sh; then
    print_pass "Error trap is configured"
else
    print_fail "Error trap is not configured"
fi

# Test 5: Check for DNF command variations (Fedora 43 compatibility)
print_test "Checking DNF command compatibility for Fedora 43..."
if grep -q "dnf config-manager add-repo" 2.sh; then
    print_pass "New DNF5 syntax 'add-repo' found"
else
    print_fail "New DNF5 syntax 'add-repo' not found"
fi

if grep -q "dnf config-manager addrepo --from-repofile" 2.sh; then
    print_pass "Alternative DNF5 syntax 'addrepo --from-repofile' found"
else
    print_fail "Alternative DNF5 syntax not found"
fi

if grep -q "dnf config-manager --add-repo" 2.sh; then
    print_pass "Legacy DNF syntax '--add-repo' found as fallback"
else
    print_fail "Legacy DNF syntax not found"
fi

# Test 6: Check for Docker repository configuration
print_test "Checking Docker repository configuration..."
if grep -q "https://download.docker.com/linux/fedora/docker-ce.repo" 2.sh; then
    print_pass "Docker repository URL is configured"
else
    print_fail "Docker repository URL not found"
fi

# Test 7: Check for required Docker packages
print_test "Checking Docker package installation..."
docker_packages=(
    "docker-ce"
    "docker-ce-cli"
    "containerd.io"
    "docker-buildx-plugin"
    "docker-compose-plugin"
)

for pkg in "${docker_packages[@]}"; do
    if grep -q "$pkg" 2.sh; then
        print_pass "Package '$pkg' is included"
    else
        print_fail "Package '$pkg' not found"
    fi
done

# Test 8: Check for Portainer installation
print_test "Checking Portainer installation steps..."
if grep -q "portainer/portainer-ce" 2.sh; then
    print_pass "Portainer CE image is specified"
else
    print_fail "Portainer CE image not found"
fi

if grep -q "docker volume create portainer_data" 2.sh; then
    print_pass "Portainer volume creation found"
else
    print_fail "Portainer volume creation not found"
fi

if grep -q "docker run.*portainer" 2.sh; then
    print_pass "Portainer container run command found"
else
    print_fail "Portainer container run command not found"
fi

# Test 9: Check for security features
print_test "Checking security features..."
if grep -q "check_root" 2.sh; then
    print_pass "Root privilege check is implemented"
else
    print_fail "Root privilege check not found"
fi

if grep -q "check_fedora_version" 2.sh; then
    print_pass "Fedora version check is implemented"
else
    print_fail "Fedora version check not found"
fi

# Test 10: Check for cleanup on error
print_test "Checking cleanup mechanisms..."
if grep -q "cleanup_on_error" 2.sh; then
    print_pass "Cleanup on error function exists"
else
    print_fail "Cleanup on error function not found"
fi

# Test 11: Check for user feedback
print_test "Checking user feedback mechanisms..."
if grep -q "print_success\|print_error\|print_warning" 2.sh; then
    print_pass "User feedback functions are used"
else
    print_fail "User feedback functions not found"
fi

# Test 12: Check shebang
print_test "Checking script shebang..."
if head -n 1 2.sh | grep -q "^#!/bin/bash"; then
    print_pass "Correct shebang is present"
else
    print_fail "Incorrect or missing shebang"
fi

# Test 13: Check for port configurations
print_test "Checking Portainer port configurations..."
if grep -q "9000" 2.sh; then
    print_pass "HTTP port 9000 is configured"
else
    print_fail "HTTP port 9000 not found"
fi

if grep -q "9443" 2.sh; then
    print_pass "HTTPS port 9443 is configured"
else
    print_fail "HTTPS port 9443 not found"
fi

# Test 14: Check for systemd service management
print_test "Checking systemd service management..."
if grep -q "systemctl.*docker" 2.sh; then
    print_pass "Docker systemd service management found"
else
    print_fail "Docker systemd service management not found"
fi

# Test 15: Check for Docker verification
print_test "Checking Docker verification steps..."
if grep -q "docker --version\|docker.*hello-world" 2.sh; then
    print_pass "Docker verification steps are present"
else
    print_fail "Docker verification steps not found"
fi

# Test 16: Check for manual fallback method
print_test "Checking for manual repository configuration fallback..."
if grep -q "curl.*docker-ce.repo" 2.sh; then
    print_pass "Manual fallback method is implemented"
else
    print_fail "Manual fallback method not found"
fi

# Summary
echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                      TEST SUMMARY                             ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo -e "${GREEN}Tests Passed: ${TEST_PASSED}${NC}"
echo -e "${RED}Tests Failed: ${TEST_FAILED}${NC}"
echo ""

if [[ $TEST_FAILED -eq 0 ]]; then
    echo -e "${GREEN}✅ All tests passed! The installer script is ready.${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed. Please review the script.${NC}"
    exit 1
fi
