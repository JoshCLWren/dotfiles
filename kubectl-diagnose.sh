#!/bin/bash
#
# kubectl-diagnose.sh
# Diagnoses kubectl connectivity issues with GKE clusters
#
# Checks:
# 1. Current public IP (what GKE sees)
# 2. Whether Netskope is running
# 3. Whether kubectl is being bypassed by Netskope
# 4. TCP connectivity to GKE API servers
# 5. kubectl access to staging and production
#

set -e

STAGING_CONTEXT="gke_yv-api-staging_us-central1_yv-api-staging"
PROD_CONTEXT="gke_yv-api-production_us-central1_yv-api-prod"
STAGING_IP="34.28.210.81"
PROD_IP="34.122.29.32"

echo "========================================"
echo "kubectl GKE Connectivity Diagnostics"
echo "========================================"
echo ""

# 1. Check public IP
echo "[1/6] Public IP (what GKE sees):"
PUBLIC_IP=$(curl -s --connect-timeout 5 ifconfig.me 2>/dev/null || echo "failed")
echo "      $PUBLIC_IP"
echo ""

# 2. Check if Netskope is running
echo "[2/6] Netskope status:"
if pgrep -f "Netskope" > /dev/null 2>&1; then
    echo "      Running"
    NETSKOPE_STATUS="on"
else
    echo "      Not running"
    NETSKOPE_STATUS="off"
fi
echo ""

# 3. Check if kubectl is being bypassed (only if Netskope is on)
echo "[3/6] Netskope kubectl bypass:"
if [ "$NETSKOPE_STATUS" = "on" ]; then
    BYPASS_COUNT=$(grep -c "Bypassing.*kubectl" /Library/Logs/Netskope/nsdebuglog.log 2>/dev/null || echo "0")
    if [ "$BYPASS_COUNT" -gt 0 ]; then
        echo "      YES - kubectl traffic is BYPASSED (not going through Netskope)"
        LAST_BYPASS=$(grep "Bypassing.*kubectl" /Library/Logs/Netskope/nsdebuglog.log 2>/dev/null | tail -1)
        echo "      Last: $LAST_BYPASS"
    else
        echo "      NO - kubectl traffic goes through Netskope"
    fi
else
    echo "      N/A - Netskope not running"
fi
echo ""

# 4. Check TCP connectivity to GKE API servers
echo "[4/6] TCP connectivity to GKE API servers:"
echo -n "      Staging ($STAGING_IP:443): "
if nc -zv -w 3 "$STAGING_IP" 443 2>&1 | grep -q "succeeded"; then
    echo "OK"
else
    echo "BLOCKED/TIMEOUT"
fi

echo -n "      Production ($PROD_IP:443): "
if nc -zv -w 3 "$PROD_IP" 443 2>&1 | grep -q "succeeded"; then
    echo "OK"
else
    echo "BLOCKED/TIMEOUT"
fi
echo ""

# 5. Test kubectl staging
echo "[5/6] kubectl staging cluster:"
if timeout 10 kubectl get nodes --context "$STAGING_CONTEXT" > /dev/null 2>&1; then
    NODE_COUNT=$(kubectl get nodes --context "$STAGING_CONTEXT" --no-headers 2>/dev/null | wc -l | tr -d ' ')
    echo "      OK ($NODE_COUNT nodes)"
else
    echo "      FAILED (timeout or auth error)"
fi
echo ""

# 6. Test kubectl production
echo "[6/6] kubectl production cluster:"
if timeout 10 kubectl get nodes --context "$PROD_CONTEXT" > /dev/null 2>&1; then
    NODE_COUNT=$(kubectl get nodes --context "$PROD_CONTEXT" --no-headers 2>/dev/null | wc -l | tr -d ' ')
    echo "      OK ($NODE_COUNT nodes)"
else
    echo "      FAILED (timeout or auth error)"
fi
echo ""

# Summary
echo "========================================"
echo "Summary"
echo "========================================"
echo "Public IP: $PUBLIC_IP"
echo "Netskope: $NETSKOPE_STATUS"
echo ""
echo "If both clusters fail:"
echo "  - From home: Need CheckPoint VPN or IP whitelist"
echo "  - From office: Contact IT/SRE about authorized networks"
echo ""
echo "Whitelisted ranges (for reference):"
echo "  - 172.19.130.0/24  (Netskope gateway - but kubectl bypassed)"
echo "  - 192.168.142.0/24 (CheckPoint VPN)"
echo "  - 205.236.56.0/24  (Office - added to staging)"
echo "  - 10.5.128.0/18    (Internal - if routing works)"
