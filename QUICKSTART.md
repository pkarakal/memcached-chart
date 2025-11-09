# Memcached Helm Chart - Quick Start Guide

## Migration from Bitnami

This chart was created as a drop-in replacement for the Bitnami Memcached chart, using only free and open-source
components.

### Key Changes from Bitnami:

1. **Image**: Official `memcached:1.6.31-alpine` from Docker Hub
2. **Exporter**: `prom/memcached-exporter:v0.14.4` from Docker Hub
3. **Service**: Headless service by default for StatefulSet pattern
4. **No Dependencies**: Removed Bitnami common library

## Quick Installation

### 1. Basic Installation (Single Instance)

```bash
helm install my-memcached ./memcached
```

This creates:

- 1 Memcached pod
- Headless service for direct pod access
- ServiceAccount with minimal permissions

### 2. Development Installation

```bash
helm install memcached-dev ./memcached \
  --set replicaCount=1 \
  --set resources.requests.memory=128Mi \
  --set resources.requests.cpu=100m
```

### 3. Production Installation

```bash
helm install memcached-prod ./memcached \
  --values values-production.yaml \
  --namespace memcached \
  --create-namespace
```

### 4. With Metrics (Prometheus)

```bash
helm install memcached ./memcached \
  --set metrics.enabled=true \
  --set metrics.serviceMonitor.enabled=true \
  --set metrics.serviceMonitor.additionalLabels.prometheus=kube-prometheus
```

## Configuration Examples

### Configure Memory Limit

```bash
helm install memcached ./memcached \
  --set extraArgs[0].name=max-memory \
  --set extraArgs[0].value=1024
```

This sets Memcached to use 1GB of memory.

### High Availability (3 replicas)

```bash
helm install memcached ./memcached \
  --set replicaCount=3 \
  --set podAntiAffinityPreset=hard \
  --set resources.requests.memory=512Mi
```

### With Custom Image

```bash
helm install memcached ./memcached \
  --set image.registry=my-registry.com \
  --set image.repository=my-memcached \
  --set image.tag=custom-tag
```

## Connecting to Memcached

### From Within the Cluster

The headless service provides direct access to each pod:

```
<release-name>-memcached-headless.<namespace>.svc.cluster.local:11211
```

Example with release name `my-cache` in namespace `default`:

```
my-cache-memcached-headless.default.svc.cluster.local:11211
```

### Test Connection

```bash
# Run a test pod
kubectl run -it --rm memcached-client --image=memcached:1.6.31-alpine -- sh

# Inside the pod, test connection
telnet my-cache-memcached-headless.default.svc.cluster.local 11211

# Try some commands
set test 0 0 5
hello
get test
quit
```

## Upgrading from Bitnami

### Option 1: Fresh Installation (Recommended)

1. Export data if needed (Memcached is a cache, typically okay to lose)
2. Delete Bitnami release:
   ```bash
   helm uninstall old-memcached
   ```
3. Install this chart:
   ```bash
   helm install memcached ./memcached -f my-values.yaml
   ```

### Option 2: In-Place Migration (Advanced)

1. Scale down Bitnami deployment:
   ```bash
   kubectl scale statefulset old-memcached --replicas=0
   ```
2. Install this chart with same release name
3. Update application connection strings if needed

## Monitoring

### Enable Metrics

```yaml
metrics:
  enabled: true
  serviceMonitor:
    enabled: true
    interval: 30s
```

### Access Metrics Manually

```bash
kubectl port-forward svc/memcached 9150:9150
curl http://localhost:9150/metrics
```

### Grafana Dashboard

Import Grafana dashboard ID: 37 (Memcached Overview)

## Troubleshooting

### Check Pod Status

```bash
kubectl get pods -l app.kubernetes.io/name=memcached
```

### View Logs

```bash
kubectl logs -l app.kubernetes.io/name=memcached
```

### Check Service

```bash
kubectl get svc -l app.kubernetes.io/name=memcached
kubectl describe svc memcached-headless
```

### Connect to Pod

```bash
kubectl exec -it memcached-0 -- sh
```

### Common Issues

**Issue**: Pods not starting

```bash
# Check events
kubectl describe pod memcached-0

# Common causes:
# - Resource limits too low
# - Image pull issues
# - Security context conflicts
```

**Issue**: Cannot connect to Memcached

```bash
# Verify service endpoints
kubectl get endpoints memcached-headless

# Test from another pod
kubectl run -it --rm test-pod --image=busybox -- telnet memcached-headless 11211
```

## Advanced Configuration

### Custom Arguments

Add Memcached command-line arguments:

```yaml
extraArgs:
  - name: max-memory
    value: "2048"
  - name: conn-limit
    value: "2048"
  - name: threads
    value: "8"
  - name: max-item-size
    value: "2m"
```

### Security Contexts

Already configured with best practices:

- Non-root user (UID 11211)
- Read-only root filesystem
- Dropped capabilities
- No privilege escalation

### Pod Disruption Budget

Create a PDB for production:

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: memcached-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app.kubernetes.io/name: memcached
```

## Uninstallation

```bash
helm uninstall memcached
```

To also delete PVCs if persistence was enabled:

```bash
kubectl delete pvc -l app.kubernetes.io/name=memcached
```

## Support

For issues and questions:

- Check the README.md for full configuration options
- Review values.yaml for all available parameters
- Consult official Memcached documentation: https://memcached.org/
