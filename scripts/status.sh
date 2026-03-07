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

echo "=== 🔗 Connectivity Check ==="
echo -n "  sdwc-api health:   "
curl -s -o /dev/null -w "%{http_code}" http://sdwc.local:8080/health 2>/dev/null || echo "unreachable"
echo ""
echo -n "  intake-api health: "
curl -s -o /dev/null -w "%{http_code}" http://intake.local:8080/api/v1/health 2>/dev/null || echo "unreachable"
echo ""
