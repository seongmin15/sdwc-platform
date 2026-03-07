#!/bin/bash

CLUSTER_NAME="sdwc-platform"

echo "🧹 Deleting k3d cluster '$CLUSTER_NAME'..."
k3d cluster delete $CLUSTER_NAME

echo "✅ Cluster removed"
