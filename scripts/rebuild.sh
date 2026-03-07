#!/bin/bash
set -e

CLUSTER_NAME="sdwc-platform"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECTS_ROOT="$(cd "$PLATFORM_ROOT/.." && pwd)"

SDWC_DIR="$PROJECTS_ROOT/SDwC"
INTAKE_DIR="$PROJECTS_ROOT/intake-assistant"

# Parse arguments: rebuild specific service or all
TARGET="${1:-all}"

rebuild_sdwc_api() {
  local img="ghcr.io/seongmin15/sdwc/sdwc-api:latest"
  echo "🐳 Rebuilding sdwc-api..."
  docker build -f "$SDWC_DIR/sdwc-api/Dockerfile" -t $img "$SDWC_DIR"
  k3d image import $img -c $CLUSTER_NAME
  kubectl rollout restart deployment sdwc-api -n sdwc
  kubectl rollout status deployment sdwc-api -n sdwc
}

rebuild_sdwc_web() {
  local img="ghcr.io/seongmin15/sdwc/sdwc-web:latest"
  echo "🐳 Rebuilding sdwc-web..."
  docker build -f "$SDWC_DIR/sdwc-web/Dockerfile" -t $img "$SDWC_DIR"
  k3d image import $img -c $CLUSTER_NAME
  kubectl rollout restart deployment sdwc-web -n sdwc
  kubectl rollout status deployment sdwc-web -n sdwc
}

rebuild_intake_api() {
  local img="ghcr.io/seongmin15/intake/intake-api:latest"
  echo "🐳 Rebuilding intake-api..."
  docker build -f "$INTAKE_DIR/intake-assistant-api/Dockerfile" -t $img "$INTAKE_DIR"
  k3d image import $img -c $CLUSTER_NAME
  kubectl rollout restart deployment intake-assistant-api -n intake
  kubectl rollout status deployment intake-assistant-api -n intake
}

rebuild_intake_web() {
  local img="ghcr.io/seongmin15/intake/intake-web:latest"
  echo "🐳 Rebuilding intake-web..."
  docker build -f "$INTAKE_DIR/intake-assistant-web/Dockerfile" -t $img "$INTAKE_DIR"
  k3d image import $img -c $CLUSTER_NAME
  kubectl rollout restart deployment intake-assistant-web -n intake
  kubectl rollout status deployment intake-assistant-web -n intake
}

case "$TARGET" in
  sdwc-api)     rebuild_sdwc_api ;;
  sdwc-web)     rebuild_sdwc_web ;;
  intake-api)   rebuild_intake_api ;;
  intake-web)   rebuild_intake_web ;;
  sdwc)         rebuild_sdwc_api; rebuild_sdwc_web ;;
  intake)       rebuild_intake_api; rebuild_intake_web ;;
  all)
    rebuild_sdwc_api
    rebuild_sdwc_web
    rebuild_intake_api
    rebuild_intake_web
    ;;
  *)
    echo "Usage: $0 [sdwc-api|sdwc-web|intake-api|intake-web|sdwc|intake|all]"
    exit 1
    ;;
esac

echo "✅ Rebuild complete"
