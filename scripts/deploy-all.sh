#!/bin/bash
set -e

CLUSTER_NAME="sdwc-platform"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECTS_ROOT="$(cd "$PLATFORM_ROOT/.." && pwd)"

SDWC_DIR="$PROJECTS_ROOT/SDwC"
INTAKE_DIR="$PROJECTS_ROOT/intake-assistant"

# Validate project directories
for dir in "$SDWC_DIR" "$INTAKE_DIR"; do
  if [ ! -d "$dir" ]; then
    echo "❌ Directory not found: $dir"
    echo "Expected layout:"
    echo "  SDwC_projects/"
    echo "  ├── SDwC/"
    echo "  ├── intake-assistant/"
    echo "  └── sdwc-platform/"
    exit 1
  fi
done

# --- Cluster ---
echo "🚀 Creating k3d cluster..."
k3d cluster create $CLUSTER_NAME \
  -p "8080:80@loadbalancer" \
  --k3s-arg "--disable=traefik@server:0" \
  || echo "Cluster already exists"

# Install Traefik via Helm for cross-namespace IngressRoute support
echo "📦 Installing Traefik..."
kubectl apply -f https://raw.githubusercontent.com/traefik/traefik/v3.0/docs/content/reference/dynamic-configuration/kubernetes-crd-definition-v1.yml 2>/dev/null || true
helm repo add traefik https://traefik.github.io/charts 2>/dev/null || true
helm repo update
helm upgrade --install traefik traefik/traefik \
  --namespace kube-system \
  --set ports.web.nodePort=80 \
  --set service.type=LoadBalancer \
  --wait 2>/dev/null || echo "Traefik already installed or Helm not available, using built-in"

# --- Namespaces ---
echo "📁 Creating namespaces..."
kubectl create namespace sdwc 2>/dev/null || true
kubectl create namespace intake 2>/dev/null || true

# --- Images ---
SDWC_API_IMAGE="ghcr.io/seongmin15/sdwc/sdwc-api:latest"
SDWC_WEB_IMAGE="ghcr.io/seongmin15/sdwc/sdwc-web:latest"
INTAKE_API_IMAGE="ghcr.io/seongmin15/intake/intake-api:latest"
INTAKE_WEB_IMAGE="ghcr.io/seongmin15/intake/intake-web:latest"

echo "🐳 Building SDwC images..."
docker build -f "$SDWC_DIR/sdwc-api/Dockerfile" -t $SDWC_API_IMAGE "$SDWC_DIR"
docker build -f "$SDWC_DIR/sdwc-web/Dockerfile" -t $SDWC_WEB_IMAGE "$SDWC_DIR"

echo "🐳 Building intake-assistant images..."
docker build -f "$INTAKE_DIR/intake-assistant-api/Dockerfile" -t $INTAKE_API_IMAGE "$INTAKE_DIR"
docker build -f "$INTAKE_DIR/intake-assistant-web/Dockerfile" -t $INTAKE_WEB_IMAGE "$INTAKE_DIR"

echo "📦 Importing images into k3d..."
k3d image import \
  $SDWC_API_IMAGE $SDWC_WEB_IMAGE \
  $INTAKE_API_IMAGE $INTAKE_WEB_IMAGE \
  -c $CLUSTER_NAME

# --- Manifests ---
echo "☸️ Applying SDwC manifests..."
kubectl apply -f "$SDWC_DIR/infra/sdwc-api/deployment.yaml" -n sdwc
kubectl apply -f "$SDWC_DIR/infra/sdwc-web/deployment.yaml" -n sdwc

echo "☸️ Applying intake-assistant manifests..."
kubectl apply -f "$INTAKE_DIR/infra/intake-assistant-api/deployment.yaml" -n intake
kubectl apply -f "$INTAKE_DIR/infra/intake-assistant-web/deployment.yaml" -n intake

echo "☸️ Applying platform ingress..."
kubectl apply -f "$PLATFORM_ROOT/ingress/platform-ingress.yaml"

# --- Wait ---
echo "⏳ Waiting for pods..."
kubectl wait --for=condition=Ready pod --all -n sdwc --timeout=120s
kubectl wait --for=condition=Ready pod --all -n intake --timeout=120s

# --- Verify ---
echo ""
echo "✅ Deployment complete!"
echo ""
echo "📍 Access:"
echo "  SDwC:             http://sdwc.local:8080"
echo "  intake-assistant: http://intake.local:8080"
echo ""
echo "💡 Add to /etc/hosts (or C:\\Windows\\System32\\drivers\\etc\\hosts):"
echo "  127.0.0.1 sdwc.local intake.local"
