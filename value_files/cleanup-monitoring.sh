#!/bin/bash
set -e

RELEASE="monitoring-dev"
NAMESPACE="monitoring"

echo "Deleting Helm release..."
helm uninstall "$RELEASE" -n "$NAMESPACE" 2>/dev/null || true

echo "Deleting namespace..."
kubectl delete namespace "$NAMESPACE" --ignore-not-found=true || true

echo "Deleting PVCs..."
kubectl delete pvc --all -n "$NAMESPACE" --ignore-not-found=true 2>/dev/null || true

echo "Deleting matching PVs..."
kubectl get pv --no-headers | awk '/monitoring|grafana|loki|prometheus/ {print $1}' | xargs -r kubectl delete pv || true

echo "Deleting Prometheus Operator CRDs..."
kubectl get crd --no-headers | awk '/monitoring.coreos.com/ {print $1}' | xargs -r kubectl delete crd || true

echo "Cleanup completed."