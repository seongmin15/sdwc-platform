#!/bin/bash

echo "=== 📦 SDwC Namespace ==="
kubectl get pods,svc -n sdwc
echo ""

echo "=== 📦 intake Namespace ==="
kubectl get pods,svc -n intake
echo ""

echo "=== 🚪 Ingress (all namespaces) ==="
kubectl get ingress -A
echo ""

echo "=== 🚀 ArgoCD ==="
kubectl get pods -n argocd
echo ""
kubectl get applications -n argocd
echo ""

echo "=== 🔗 Connectivity Check ==="
echo -n "  sdwc-api health:   "
curl -sk -o /dev/null -w "%{http_code}" https://sdwc.local:8443/health 2>/dev/null || echo "unreachable"
echo ""
echo -n "  intake-api health: "
curl -sk -o /dev/null -w "%{http_code}" https://intake.local:8443/api/v1/health 2>/dev/null || echo "unreachable"
echo ""
