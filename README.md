# Kubernetes Observability Lab

> A complete observability stack deployed on **Minikube** with isolated **development** and **production** environments using **Prometheus, Grafana, Alertmanager, Loki, and Promtail**.

---

## Table of Contents
- [Overview](#overview)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Environment Preparation](#environment-preparation)
- [Configuration Files](#configuration-files)
- [Deployment Steps](#deployment-steps)
- [Accessing the Services](#accessing-the-services)
- [Verification](#verification)
- [Why use `helm upgrade --install`?](#why-use-helm-upgrade---install)
- [How Alerts Are Defined](#how-alerts-are-defined)
- [Differences Between Dev and Prod](#differences-between-dev-and-prod)
- [Issues Encountered and Resolution](#issues-encountered-and-resolution)
- [Conclusion](#conclusion)

---

## Overview

This project demonstrates a full **Kubernetes observability lab** running on **Minikube** with two separate environments:

- `monitoring-dev`
- `monitoring-prod`

The observability platform includes:

- **Prometheus** for metrics collection
- **Grafana** for dashboards and visualization
- **Alertmanager** for alert handling
- **Loki** for centralized log aggregation
- **Promtail** for shipping pod logs to Loki

The goal of this lab was to build a clean and practical monitoring stack with clear separation between development and production configurations.

---

## Architecture

The stack is composed of the following components:

- **Prometheus** scrapes and stores metrics from Kubernetes services and workloads
- **Grafana** provides dashboards for metrics and logs visualization
- **Alertmanager** is deployed as part of the Prometheus stack for alert routing
- **Loki** stores logs in a cost-efficient log aggregation system
- **Promtail** runs as the log collector and forwards logs from pods to Loki

### Environment Layout

- **Development Namespace:** `monitoring-dev`
- **Production Namespace:** `monitoring-prod`

Both environments use the same observability architecture, while applying different configuration values for retention, persistence, and operational behavior.

---

## Project Structure

```text
.
├── values-dev.yaml
├── values-prod.yaml
├── loki-values-dev.yaml
├── loki-values-prod.yaml
├── screenshots/
│   ├── grafana-dashboard-dev.png
│   ├── prometheus-targets-dev.png
│   ├── loki-dashboard-dev.png
│   └── final-status.png
└── README.md
```

---

## Prerequisites

Before starting, the following tools were installed:

- **Minikube**
- **kubectl**
- **Helm**

---

## Environment Preparation

### 1. Start Minikube

```powershell
minikube start
```

### 2. Enable Ingress Addon

```powershell
minikube addons enable ingress
```

### 3. Create Monitoring Namespaces

```powershell
kubectl create namespace monitoring-dev
kubectl create namespace monitoring-prod
```

### 4. Add Helm Repositories

```powershell
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
```

---

## Configuration Files

### `values-dev.yaml`

This file is used for the **development** Prometheus/Grafana deployment.

Key characteristics:

- Grafana admin password configured for dev
- Prometheus retention set to **7d**
- `node-exporter` disabled in dev to prevent host-port conflicts on single-node Minikube

### `values-prod.yaml`

This file is used for the **production** Prometheus/Grafana deployment.

Key characteristics:

- Grafana admin password configured for prod
- Prometheus retention set to **30d**
- `node-exporter` enabled in prod

### `loki-values-dev.yaml`

This file is used for the **development** Loki deployment.

Key characteristics:

- Loki enabled
- Promtail enabled
- Grafana disabled in the Loki chart
- Persistence disabled

### `loki-values-prod.yaml`

This file is used for the **production** Loki deployment.

Key characteristics:

- Loki enabled
- Promtail enabled
- Grafana disabled in the Loki chart
- Persistence enabled with **10Gi**

---

## Deployment Steps

### Deploy Prometheus Stack in Development

```powershell
helm upgrade --install monitoring-dev prometheus-community/kube-prometheus-stack -n monitoring-dev -f values-dev.yaml
```

### Deploy Prometheus Stack in Production

```powershell
helm upgrade --install monitoring-prod prometheus-community/kube-prometheus-stack -n monitoring-prod -f values-prod.yaml
```

### Deploy Loki Stack in Development

```powershell
helm upgrade --install loki-dev grafana/loki-stack -n monitoring-dev -f loki-values-dev.yaml
```

### Deploy Loki Stack in Production

```powershell
helm upgrade --install loki-prod grafana/loki-stack -n monitoring-prod -f loki-values-prod.yaml
```

---

## Accessing the Services

### Access Grafana in Development

```powershell
kubectl port-forward svc/monitoring-dev-grafana -n monitoring-dev 3000:80
```

Open in browser:

```text
http://localhost:3000
```

### Access Prometheus in Development

```powershell
kubectl port-forward svc/monitoring-dev-kube-promet-prometheus -n monitoring-dev 9090:9090
```

Open in browser:

```text
http://localhost:9090/targets
```

---

## Verification

After deployment, the stack was verified using dashboards, target health, log queries, and final pod/release status.

### Grafana Dashboard

The Grafana dashboard successfully displayed Prometheus metrics and active visual panels.

![Grafana Dashboard](screenshots/grafana-dashboard-dev.png)

### Prometheus Targets

Prometheus target health page confirmed that monitored endpoints were in `UP` state.

![Prometheus Targets](screenshots/prometheus-targets-dev.png)

### Loki Logs

Loki successfully ingested and displayed logs from the cluster through Grafana Explore.

![Loki Dashboard](screenshots/loki-dashboard-dev.png)

### Final Deployment Status

All required pods and Helm releases were successfully deployed in both namespaces.

![Final Status](screenshots/final-status.png)

---

## Why use `helm upgrade --install`?

The command `helm upgrade --install` is useful because it combines **installation** and **upgrade** into a single repeatable deployment command.

### Benefits

- If the release does not exist, Helm installs it
- If the release already exists, Helm upgrades it
- It simplifies repeated deployment during testing and troubleshooting
- It is ideal for lab environments where configuration files are adjusted multiple times

This approach makes the deployment process faster, cleaner, and more maintainable.

---

## How Alerts Are Defined

Alerts in the Prometheus stack are typically defined using **Prometheus alerting rules**.

### Basic Alert Flow

1. Prometheus evaluates rule expressions periodically
2. When a condition becomes true, an alert is triggered
3. The alert is sent to **Alertmanager**
4. Alertmanager handles grouping, routing, silencing, and notification delivery

In this lab, **Alertmanager** was deployed as part of `kube-prometheus-stack`, which provides the standard Kubernetes alerting architecture.

---

## Differences Between Dev and Prod

Although both environments use the same architecture, several configuration differences were intentionally applied.

### Development Environment
- Namespace: `monitoring-dev`
- Prometheus retention: **7d**
- Loki persistence: **disabled**
- `node-exporter`: **disabled**
- Used as a lighter environment for testing and validation

### Production Environment
- Namespace: `monitoring-prod`
- Prometheus retention: **30d**
- Loki persistence: **enabled (10Gi)**
- `node-exporter`: **enabled**
- Used as the more complete and persistent deployment model

These differences demonstrate how the same monitoring stack can be adapted to different operational requirements.

---

## Issues Encountered and Resolution

During deployment on **single-node Minikube**, a scheduling conflict occurred when `node-exporter` was enabled in both namespaces.

### Problem
`node-exporter` uses host-level ports, and since Minikube had only one node, the second deployment could not schedule successfully.

### Resolution
- `node-exporter` remained enabled in **production**
- `node-exporter` was disabled in **development**

This preserved a more production-like deployment in `monitoring-prod` while avoiding host-port conflicts in the lab environment.

---

## Conclusion

This lab successfully implemented a complete Kubernetes observability environment on **Minikube** using isolated **development** and **production** namespaces.

### Implemented Components
- **Prometheus** for metrics
- **Grafana** for visualization
- **Alertmanager** for alert handling
- **Loki** for logging
- **Promtail** for log collection

### Final Result
The deployment was validated through:

- Working Grafana dashboards
- Healthy Prometheus targets
- Successful Loki log queries
- Fully running pods in both environments
- Successfully deployed Helm releases in both namespaces

This project provides a strong foundation for Kubernetes monitoring, troubleshooting, and environment-specific observability design.