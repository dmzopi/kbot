# Observability Stack (Flux + Kubernetes)

This repository provisions a full observability stack on Kubernetes using Flux GitOps.

---

## 🚀 Deployed Components

### 📦 Cert-Manager
- Installed via Helm through Flux
- Provides CRDs for TLS certificates
- Required for OpenTelemetry Operator webhook certificates

---

### 📊 OpenTelemetry Operator
- Installed via Helm via Flux
- Manages `OpenTelemetryCollector` CRDs
- Enables deployment of OTEL collectors in Kubernetes

---

### 🔭 OpenTelemetry Collector
- Deployed as Kubernetes custom resource (`OpenTelemetryCollector`)
- Mode: Deployment
- Receives telemetry via OTLP (gRPC + HTTP)
- Pipelines:
  - Metrics → Prometheus exporter
  - Traces → Tempo
- Uses contrib-compatible configuration

---

### 📈 Prometheus
- Installed via Helm via Flux
- Scrapes cluster and application metrics
- Integrated with Grafana as datasource

---

### Loki
- Installed via Helm via Flux
- Centralized log aggregation
- Exposed via `loki-gateway` service
- Requires tenant header:
  - `X-Scope-OrgID: foo`

---

### Tempo
- Distributed tracing backend
- Receives traces from OpenTelemetry Collector
- Integrated with Grafana for trace exploration

---

### Grafana
- Installed via Helm via Flux
- Configured via Git-provisioned datasources

#### Datasources:
- Prometheus
- Loki
- Tempo

#### Features:
- Loki → Tempo trace correlation via derived fields
- Header-based Loki multi-tenancy support
- TraceID extraction from logs:
  - Regex: `trace_id":"([a-f0-9]+)"`
- Clickable trace links directly from logs

---

## Observability Flow
---

##  Key Implementation Details

- Fully GitOps-managed via Flux
- Helm charts used for all core components
- Namespace separation:
  - `cert-manager`
  - `monitoring`
- Service discovery via Kubernetes DNS
- Datasources provisioned via Grafana Helm chart values
- Loki configured with `X-Scope-OrgID` header support

---

## Installation manual

- Deploy content of this folder to your cluster folder in FluxCD repo

##  Notes

- Grafana datasources are read-only (managed by Flux)
- OpenTelemetry Collector requires contrib-compatible build
- Loki trace correlation depends on correct regex extraction of `trace_id`
- Tempo trace search works independently via trace ID lookup

---

## Demo

![Image](otel_flux.gif)