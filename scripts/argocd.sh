#!/bin/bash
set -e

COMMAND="${1:-status}"

case "$COMMAND" in
  status)
    echo "=== ArgoCD Pods ==="
    kubectl get pods -n argocd
    echo ""
    echo "=== ArgoCD Applications ==="
    kubectl get applications -n argocd
    ;;

  restart)
    echo "🔄 Restarting ArgoCD..."
    kubectl rollout restart deployment argocd-server -n argocd
    kubectl rollout restart deployment argocd-repo-server -n argocd
    kubectl rollout restart statefulset argocd-application-controller -n argocd
    echo "⏳ Waiting for ArgoCD to be ready..."
    kubectl rollout status deployment argocd-server -n argocd --timeout=120s
    kubectl rollout status deployment argocd-repo-server -n argocd --timeout=120s
    kubectl rollout status statefulset argocd-application-controller -n argocd --timeout=120s
    echo "✅ ArgoCD restarted."
    ;;

  password)
    echo "🔑 ArgoCD admin password:"
    kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d
    echo ""
    ;;

  ui)
    echo "🌐 Opening ArgoCD UI on https://localhost:8080 ..."
    echo "   Login: admin / $(kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d)"
    kubectl port-forward svc/argocd-server -n argocd 8080:443
    ;;

  sync)
    APP="${2:-}"
    if [ -z "$APP" ]; then
      echo "🔄 Syncing all ArgoCD applications..."
      kubectl get applications -n argocd -o name | while read app; do
        kubectl patch "$app" -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"HEAD"}}}'
        echo "  Triggered sync: $app"
      done
    else
      echo "🔄 Syncing $APP..."
      kubectl patch application "$APP" -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"HEAD"}}}'
    fi
    echo "✅ Sync triggered."
    ;;

  *)
    echo "Usage: $0 {status|restart|password|ui|sync [app-name]}"
    echo ""
    echo "Commands:"
    echo "  status    Show ArgoCD pods and application status"
    echo "  restart   Restart ArgoCD server components"
    echo "  password  Show admin password"
    echo "  ui        Port-forward ArgoCD UI to localhost:8080"
    echo "  sync      Trigger sync (all apps or specific app)"
    exit 1
    ;;
esac
