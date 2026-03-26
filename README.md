<p align="center">
  <img src="https://img.shields.io/badge/Grafana-Dashboards-F46800?style=for-the-badge&logo=grafana&logoColor=white" alt="Grafana" />
  <img src="https://img.shields.io/badge/Prometheus-Monitoring-E6522C?style=for-the-badge&logo=prometheus&logoColor=white" alt="Prometheus" />
</p>

<h1 align="center">Kubernetes Observability Lab</h1>

<p align="center">
  Full observability stack on Minikube using Prometheus, Grafana, Alertmanager, Loki and Promtail
</p>

---

## Goal

Deploy a full observability stack (**metrics, alerts, logs**) on **Minikube** using **Helm** and separate namespaces for **dev/prod parity**.

This repository includes:

- Helm values files
- Deployment commands
- Screenshots of dashboards and logs
- Short explanations for the required assignment questions

---

## Deliverables

This repository provides:

- `values-dev.yaml`
- `values-prod.yaml`
- `loki-values-dev.yaml`
- `loki-values-prod.yaml`
- Screenshots of:
  - Grafana dashboards
  - Prometheus targets
  - Loki logs
  - Final running status
- Explanation of:
  - Why `helm upgrade --install` is used
  - How alerts are configured
  - Differences between dev and prod

---

## Step 1 — Prepare the Environment

### Install Minikube

```powershell
minikube start
```

### Install Helm

Helm was used as the package manager for deploying the monitoring stack charts.

### Create Namespaces

```powershell
kubectl create namespace monitoring-dev
kubectl create namespace monitoring-prod
```

---

## Step 2 — Add Helm Repositories

```powershell
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
```

---

## Step 3 — Prepare Values Files

### `values-dev.yaml`

```yaml
grafana:
  adminPassword: devadmin
  service:
    type: ClusterIP

prometheus:
  prometheusSpec:
    retention: 7d
```

### `values-prod.yaml`

```yaml
grafana:
  adminPassword: prodadmin
  service:
    type: ClusterIP

prometheus:
  prometheusSpec:
    retention: 30d
```

### `loki-values-dev.yaml`

```yaml
loki:
  persistence:
    enabled: false

promtail:
  enabled: true
```

### `loki-values-prod.yaml`

```yaml
loki:
  persistence:
    enabled: true
    size: 10Gi

promtail:
  enabled: true
```

### Summary

- **Dev** uses shorter Prometheus retention: `7d`
- **Prod** uses longer Prometheus retention: `30d`
- **Dev Loki** does not use persistence
- **Prod Loki** uses persistent storage with `10Gi`

---

## Step 4 — Deploy Prometheus & Grafana

### Dev Environment

```powershell
helm upgrade --install monitoring-dev prometheus-community/kube-prometheus-stack -n monitoring-dev -f values-dev.yaml
```

### Prod Environment

```powershell
helm upgrade --install monitoring-prod prometheus-community/kube-prometheus-stack -n monitoring-prod -f values-prod.yaml
```

### Why `helm upgrade --install` is used

`helm upgrade --install` is used because it combines both installation and upgrade in one command.

Benefits:

- If the release does not exist, Helm installs it
- If the release already exists, Helm upgrades it
- It avoids failures caused by re-running install commands
- It supports idempotent deployment
- It is practical for repeated lab testing and troubleshooting

---

## Step 5 — Deploy Loki (Logging)

### Dev Environment

```powershell
helm upgrade --install loki-dev grafana/loki-stack -n monitoring-dev -f loki-values-dev.yaml
```

### Prod Environment

```powershell
helm upgrade --install loki-prod grafana/loki-stack -n monitoring-prod -f loki-values-prod.yaml
```

### Logging Purpose

This deployment allows:

- Collecting Kubernetes pod logs
- Sending logs to Loki for centralized storage
- Viewing logs in Grafana

---

## Step 6 — Port Forward Dashboards

### Grafana (Dev)

```powershell
kubectl port-forward svc/monitoring-dev-grafana -n monitoring-dev 3000:80
```

Open:

```text
http://localhost:3000
```

Login:

- **Username:** `admin`
- **Password:** `devadmin`

### Prometheus (Dev)

```powershell
kubectl port-forward svc/monitoring-dev-kube-prometheus-prometheus -n monitoring-dev 9090:9090
```

Open:

```text
http://localhost:9090/targets
```

### Loki (Dev)

```powershell
kubectl port-forward svc/loki -n monitoring-dev 3100:3100
```

### If service names differ

Check the exact generated service names with:

```powershell
kubectl get svc -n monitoring-dev
kubectl get svc -n monitoring-prod
```

---

## Step 7 — Explore Dashboards

After deployment, Grafana and Prometheus were used to verify the environment.

### Verification Performed

1. Accessed Grafana on `http://localhost:3000`
2. Viewed dashboards for cluster and monitoring data
3. Confirmed Prometheus targets were in `UP` state
4. Queried logs from Loki inside Grafana Explore

### Screenshots

#### Grafana Dashboard

![Grafana Dashboard](screenshots/grafana-dashboard-dev.png)

#### Prometheus Targets

![Prometheus Targets](screenshots/prometheus-targets-dev.png)

#### Loki Logs

![Loki Dashboard](screenshots/loki-dashboard-dev.png)

#### Final Deployment Status

![Final Status](screenshots/final-status.png)

---

## Step 8 — Setup Alerts (Optional)

The assignment defines alerts as an optional step.

In the Prometheus stack, alerts are typically configured through:

- **Prometheus alerting rules**
- **Alertmanager** for routing and handling alerts

### How alerts are configured

The general flow is:

1. Prometheus evaluates alert rules
2. If a rule condition becomes true, an alert is triggered
3. The alert is sent to Alertmanager
4. Alertmanager groups, routes, silences, or forwards the alert

### Status in this repository

At this stage:

- **Alertmanager** is deployed as part of `kube-prometheus-stack`
- No custom `PrometheusRule` manifest is included in this repository
- No dedicated custom alert rule was added as part of this submission

This means the stack is **alert-ready**, but custom alert rules were **not configured here**

---

## Step 9 — Dev / Prod Parity

The project uses separate namespaces and different Helm values to demonstrate environment parity with configuration differences.

### Dev

- Namespace: `monitoring-dev`
- Grafana password: `devadmin`
- Prometheus retention: `7d`
- Loki persistence: disabled

### Prod

- Namespace: `monitoring-prod`
- Grafana password: `prodadmin`
- Prometheus retention: `30d`
- Loki persistence: enabled
- Loki persistent volume size: `10Gi`

### Explanation

Both environments use the same charts and deployment model, but different values files.  
This demonstrates how the same observability architecture can be adapted for different requirements.

---

## Step 10 — GitOps Bonus (Optional)

GitOps bonus was **not implemented** in this submission.

Possible future extension:

- Store Helm values in GitHub
- Use ArgoCD to watch the repository
- Automatically sync changes into dev/prod environments

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

## Conclusion

This lab successfully deployed a Kubernetes observability stack on Minikube using:

- Prometheus
- Grafana
- Alertmanager
- Loki
- Promtail

The repository includes the required values files, deployment steps, screenshots, and explanations requested in the assignment.