---
title: "Monitoring"
draft: false
images: []
weight: 750
---

Package Operator exports metrics on the `/metrics` endpoint which can be used
to monitor PKO and packages. These are exported by the
`package-operator-manager` pod. In order to monitor PKO a monitoring
stack including [Prometheus Operator](
<https://github.com/prometheus-operator/prometheus-operator>)
is required. This example will assume you have Prometheus installed.

## RBAC

In order for the Prometheus instance to discover the PKO target it requires the
appropriate RBAC role to discover pods, services and endpoints within the PKO
namespace. The following is an example role with the necessary permissions:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: prometheus
  namespace: package-operator-system
rules:
- apiGroups:
  - ""
  resources:
  - services
  - endpoints
  - pods
  verbs:
  - get
  - list
  - watch
---
# other YAML document
```

The following is an example rolebinding to add this role to the service account
for your Prometheus instance:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: prometheus
  namespace: package-operator-system
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: prometheus
subjects:
- kind: ServiceAccount
  name: <your-prometheus-service-account>
  namespace: <you-monitoring-stack-namespace>

```

Prometheus must also be able to reach the `package-operator-manager` pod,
e.g. no NetworkPolicies blocking traffic.

## Service and Pod Discovery

Ensure your Prometheus instance is able to select service monitors and/or pod
monitors from the PKO namespace. For example, using the namespace selector
and the labels on the PKO service and pods:

```yaml
podMonitorSelector:
  matchLabels:
    app.kubernetes.io/name: package-operator
podMonitorNamespaceSelector:
  matchLabels:
    kubernetes.io/metadata.name: package-operator-system
serviceMonitorSelector:
  matchLabels:
    app.kubernetes.io/name: package-operator
serviceMonitorNamespaceSelector:
  matchLabels:
    kubernetes.io/metadata.name: package-operator-system
```

### Service Monitopr

Use the following service monitor to scrape metrics from PKO:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  labels:
    app.kubernetes.io/name: package-operator
  name: package-operator
  namespace: package-operator-system
spec:
  endpoints:
  - port: metrics
    path: /metrics
  namespaceSelector:
    matchNames:
    - package-operator-system
  selector:
    matchLabels:
      app.kubernetes.io/name: package-operator
```

## Pod Monitor

Alternatively, use a pod monitor to scrape metrics:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  labels:
    app.kubernetes.io/name: package-operator
  name: package-operator
  namespace: package-operator-system
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: package-operator
  namespaceSelector:
    matchNames:
    - package-operator-system
  podMetricsEndpoints:
  - port: metrics
    path: /metrics
```
