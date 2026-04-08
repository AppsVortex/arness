# Kubernetes Patterns

Manifest organization, Helm chart structure, and idiomatic patterns for Kubernetes infrastructure definitions. Covers both raw kubectl manifests and Helm-based deployments.

---

## Manifest Organization

### Flat Structure (Simple Applications)

```
k8s/
├── namespace.yaml
├── deployment.yaml
├── service.yaml
├── ingress.yaml
├── configmap.yaml
├── secret.yaml
├── hpa.yaml
└── networkpolicy.yaml
```

### Per-Component Structure (Multi-Service)

```
k8s/
├── base/
│   ├── namespace.yaml
│   └── networkpolicy.yaml
├── api/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── hpa.yaml
│   └── configmap.yaml
├── worker/
│   ├── deployment.yaml
│   └── configmap.yaml
├── frontend/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── ingress.yaml
└── database/
    ├── statefulset.yaml
    ├── service.yaml
    ├── pvc.yaml
    └── secret.yaml
```

### Kustomize Structure (Multi-Environment)

```
k8s/
├── base/
│   ├── kustomization.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   └── configmap.yaml
├── overlays/
│   ├── dev/
│   │   ├── kustomization.yaml
│   │   ├── replicas-patch.yaml
│   │   └── configmap-patch.yaml
│   ├── staging/
│   │   ├── kustomization.yaml
│   │   ├── replicas-patch.yaml
│   │   └── ingress-patch.yaml
│   └── prod/
│       ├── kustomization.yaml
│       ├── replicas-patch.yaml
│       ├── hpa.yaml
│       └── ingress-patch.yaml
```

---

## Core Manifest Patterns

### Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-api
  namespace: myapp
  labels:
    app.kubernetes.io/name: myapp
    app.kubernetes.io/component: api
    app.kubernetes.io/managed-by: arn-infra
spec:
  replicas: 2
  selector:
    matchLabels:
      app.kubernetes.io/name: myapp
      app.kubernetes.io/component: api
  template:
    metadata:
      labels:
        app.kubernetes.io/name: myapp
        app.kubernetes.io/component: api
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1001
        fsGroup: 1001
      containers:
        - name: api
          image: myregistry/myapp-api:1.0.0
          ports:
            - containerPort: 3000
              protocol: TCP
          env:
            - name: NODE_ENV
              value: production
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: myapp-secrets
                  key: database-url
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 500m
              memory: 512Mi
          livenessProbe:
            httpGet:
              path: /health
              port: 3000
            initialDelaySeconds: 10
            periodSeconds: 30
          readinessProbe:
            httpGet:
              path: /ready
              port: 3000
            initialDelaySeconds: 5
            periodSeconds: 10
          securityContext:
            readOnlyRootFilesystem: true
            allowPrivilegeEscalation: false
            capabilities:
              drop:
                - ALL
      topologySpreadConstraints:
        - maxSkew: 1
          topologyKey: kubernetes.io/hostname
          whenUnsatisfiable: DoNotSchedule
          labelSelector:
            matchLabels:
              app.kubernetes.io/name: myapp
              app.kubernetes.io/component: api
```

### Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: myapp-api
  namespace: myapp
  labels:
    app.kubernetes.io/name: myapp
    app.kubernetes.io/component: api
spec:
  type: ClusterIP
  selector:
    app.kubernetes.io/name: myapp
    app.kubernetes.io/component: api
  ports:
    - port: 80
      targetPort: 3000
      protocol: TCP
```

### Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp-ingress
  namespace: myapp
  labels:
    app.kubernetes.io/name: myapp
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/rate-limit-rps: "10"
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - api.myapp.example.com
      secretName: myapp-tls
  rules:
    - host: api.myapp.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: myapp-api
                port:
                  number: 80
```

### HorizontalPodAutoscaler

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: myapp-api-hpa
  namespace: myapp
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp-api
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
```

### NetworkPolicy

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: myapp-api-netpol
  namespace: myapp
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: myapp
      app.kubernetes.io/component: api
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: ingress-nginx
      ports:
        - protocol: TCP
          port: 3000
  egress:
    - to:
        - podSelector:
            matchLabels:
              app.kubernetes.io/component: database
      ports:
        - protocol: TCP
          port: 5432
    - to:  # Allow DNS resolution
        - namespaceSelector: {}
      ports:
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 53
```

### ConfigMap and Secret

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: myapp-config
  namespace: myapp
data:
  APP_PORT: "3000"
  LOG_LEVEL: "info"
  CACHE_TTL: "300"
---
apiVersion: v1
kind: Secret
metadata:
  name: myapp-secrets
  namespace: myapp
type: Opaque
stringData:
  database-url: "" # Set via CI/CD or sealed-secrets
  api-key: ""      # Never commit real values
```

---

## Helm Chart Structure

### Standard Chart Layout

```
charts/myapp/
├── Chart.yaml
├── values.yaml
├── values-dev.yaml
├── values-staging.yaml
├── values-prod.yaml
├── templates/
│   ├── _helpers.tpl
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── hpa.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   ├── serviceaccount.yaml
│   ├── networkpolicy.yaml
│   └── NOTES.txt
└── .helmignore
```

### Chart.yaml

```yaml
apiVersion: v2
name: myapp
description: MyApp Helm chart for Kubernetes
type: application
version: 1.0.0
appVersion: "1.0.0"
```

### values.yaml (defaults)

```yaml
replicaCount: 1

image:
  repository: myregistry/myapp
  tag: "1.0.0"
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 80
  targetPort: 3000

ingress:
  enabled: false
  className: nginx
  hosts:
    - host: myapp.example.com
      paths:
        - path: /
          pathType: Prefix
  tls: []

resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi

autoscaling:
  enabled: false
  minReplicas: 1
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70

env: {}
secrets: {}

nodeSelector: {}
tolerations: []
affinity: {}
```

### values-prod.yaml

```yaml
replicaCount: 3

ingress:
  enabled: true
  className: nginx
  hosts:
    - host: api.myapp.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: myapp-tls
      hosts:
        - api.myapp.com

resources:
  requests:
    cpu: 250m
    memory: 256Mi
  limits:
    cpu: "1"
    memory: "1Gi"

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 20
  targetCPUUtilizationPercentage: 70
```

### templates/_helpers.tpl

```yaml
{{- define "myapp.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "myapp.labels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "myapp.selectorLabels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
```

---

## Validation Commands

### kubectl

```bash
# Validate manifests locally (no server contact)
kubectl apply --dry-run=client -f k8s/

# Validate against the cluster API
kubectl apply --dry-run=server -f k8s/

# View what would be applied
kubectl diff -f k8s/
```

### Helm

```bash
# Lint the chart
helm lint charts/myapp/

# Template rendering (preview generated manifests)
helm template myapp charts/myapp/ -f charts/myapp/values-dev.yaml

# Dry-run install
helm install myapp charts/myapp/ --dry-run --debug -f charts/myapp/values-dev.yaml

# Install
helm install myapp charts/myapp/ -f charts/myapp/values-prod.yaml -n myapp

# Upgrade
helm upgrade myapp charts/myapp/ -f charts/myapp/values-prod.yaml -n myapp
```

### Kustomize

```bash
# Build and preview
kubectl kustomize k8s/overlays/dev/

# Apply
kubectl apply -k k8s/overlays/dev/
```

---

## Labeling Convention

Use the Kubernetes recommended labels:

| Label | Purpose | Example |
|-------|---------|---------|
| `app.kubernetes.io/name` | Application name | `myapp` |
| `app.kubernetes.io/component` | Component role | `api`, `worker`, `frontend` |
| `app.kubernetes.io/instance` | Instance identifier | `myapp-prod` |
| `app.kubernetes.io/version` | Application version | `1.0.0` |
| `app.kubernetes.io/managed-by` | Management tool | `helm`, `arn-infra` |
| `app.kubernetes.io/part-of` | Higher-level app | `myapp-suite` |

---

## Best Practices Summary

1. **Namespaces:** Isolate applications in dedicated namespaces. Never use `default`.
2. **Resource limits:** Always set CPU and memory requests and limits on every container.
3. **Security context:** Run as non-root, read-only filesystem, drop all capabilities.
4. **Health probes:** Define both liveness and readiness probes on every container.
5. **Network policies:** Default-deny, then allow only required communication paths.
6. **Labels:** Follow the `app.kubernetes.io/` convention for all resources.
7. **Secrets:** Never commit real secret values. Use sealed-secrets, external-secrets, or CI/CD injection.
8. **Image tags:** Pin specific versions. Never use `:latest` in production.
9. **Pod disruption budgets:** Set PDBs for production deployments to ensure availability during upgrades.
10. **Topology spread:** Use `topologySpreadConstraints` to distribute pods across nodes/zones.
