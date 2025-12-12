#!/bin/bash
#
# kubectl-quick-test.sh
# Quick test of kubectl connectivity to GKE clusters
#
# Usage: ./kubectl-quick-test.sh
#

echo "IP: $(curl -s --connect-timeout 3 ifconfig.me 2>/dev/null || echo 'failed')"
echo ""
echo "Staging:    $(timeout 8 kubectl get nodes --context gke_yv-api-staging_us-central1_yv-api-staging --no-headers 2>/dev/null | wc -l | tr -d ' ') nodes" || echo "Staging:    FAILED"
echo "Production: $(timeout 8 kubectl get nodes --context gke_yv-api-production_us-central1_yv-api-prod --no-headers 2>/dev/null | wc -l | tr -d ' ') nodes" || echo "Production: FAILED"
