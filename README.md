# Memcached Helm Chart

This Helm chart deploys Memcached on a Kubernetes cluster using free and open-source components.

## Introduction

This chart bootstraps a [Memcached](https://memcached.org/) deployment on a [Kubernetes](https://kubernetes.io) cluster
using the [Helm](https://helm.sh) package manager.

## Key Features

- **Free and Open Source**: Uses the official Memcached Docker image from Docker Hub
- **Headless Service by Default**: Enables direct pod-to-pod communication
- **No Bitnami Dependencies**: Completely independent of Bitnami infrastructure
- **Production Ready**: Includes security contexts, resource limits, and health checks
- **Metrics Support**: Optional Prometheus exporter integration using prom/memcached-exporter
- **Highly Configurable**: Extensive configuration options via values.yaml

## Prerequisites

- Kubernetes 1.19+
- Helm 3.8.0+

## Installing the Chart

To install the chart with the release name `my-memcached`:

```bash
helm install my-memcached ./memcached
```

The command deploys Memcached on the Kubernetes cluster with the default configuration. The [Parameters](#parameters)
section lists the parameters that can be configured during installation.

## Uninstalling the Chart

To uninstall/delete the `my-memcached` deployment:

```bash
helm uninstall my-memcached
```

## Key Differences from Bitnami Chart

1. **Image Source**: Uses official `memcached:alpine` from Docker Hub instead of Bitnami images
2. **Default Service Type**: Headless service (ClusterIP: None) for StatefulSet pattern
3. **Metrics Exporter**: Uses `prom/memcached-exporter` instead of Bitnami's exporter
4. **Simplified Structure**: Removed Bitnami-specific helpers and common library dependencies
5. **Security First**: Enhanced security contexts with read-only root filesystem

## Configuration

The following table lists the configurable parameters of the Memcached chart and their default values. All parameters
are documented with comments in the `values.yaml` file.

### Global Parameters

| Parameter                   | Description                                     | Default |
|-----------------------------|-------------------------------------------------|---------|
| `global.imageRegistry`    | Global Docker image registry                    | `""`  |
| `global.imagePullSecrets` | Global Docker registry secret names as an array | `[]`  |

### Common Parameters

| Parameter             | Description                                     | Default           |
|-----------------------|-------------------------------------------------|-------------------|
| `kubeVersion`       | Override Kubernetes version detection           | `""`            |
| `nameOverride`      | String to partially override memcached.fullname | `""`            |
| `fullnameOverride`  | String to fully override memcached.fullname     | `""`            |
| `clusterDomain`     | Kubernetes cluster domain name                  | `cluster.local` |
| `commonLabels`      | Labels to add to all deployed objects           | `{}`            |
| `commonAnnotations` | Annotations to add to all deployed objects      | `{}`            |

### Memcached Image Parameters

| Parameter             | Description                                      | Default           |
|-----------------------|--------------------------------------------------|-------------------|
| `image.registry`    | Memcached image registry                         | `docker.io`     |
| `image.repository`  | Memcached image repository                       | `memcached`     |
| `image.tag`         | Memcached image tag (immutable tags recommended) | `1.6.31-alpine` |
| `image.pullPolicy`  | Image pull policy                                | `IfNotPresent`  |
| `image.pullSecrets` | Memcached image pull secrets                     | `[]`            |

### Memcached Configuration Parameters

| Parameter                          | Description                                                                     | Default    |
|------------------------------------|---------------------------------------------------------------------------------|------------|
| `replicaCount`                   | Number of Memcached replicas                                                    | `1`      |
| `memcached.allocatedMemory`      | Maximum memory to use for items in MB                                           | `64`     |
| `memcached.maxItemMemory`        | Max item size in MB                                                             | `1`      |
| `memcached.connectionLimit`      | Maximum simultaneous connections                                                | `1024`   |
| `memcached.extendedOptions`      | Extended memory options                                                         | `modern` |
| `memcached.extraExtendedOptions` | Additional extended options (extstore auto-configured when persistence enabled) | `""`     |
| `memcached.verbosity`            | Verbosity level (v, vv, vvv)                                                    | `v`      |
| `memcached.port`                 | Memcached port                                                                  | `11211`  |

### Authentication Parameters

| Parameter               | Description                                 | Default   |
|-------------------------|---------------------------------------------|-----------|
| `auth.enabled`        | Enable SASL authentication                  | `false` |
| `auth.username`       | Memcached SASL username                     | `""`    |
| `auth.password`       | Memcached SASL password                     | `""`    |
| `auth.existingSecret` | Name of existing secret containing password | `""`    |

### Persistence Parameters

| Parameter                    | Description                                                      | Default               |
|------------------------------|------------------------------------------------------------------|-----------------------|
| `persistence.enabled`      | Enable persistence using PVC (automatically configures extstore) | `false`             |
| `persistence.storageClass` | Persistent Volume storage class                                  | `""`                |
| `persistence.annotations`  | Additional custom annotations for PVC                            | `{}`                |
| `persistence.labels`       | Additional custom labels for PVC                                 | `{}`                |
| `persistence.accessModes`  | Persistent Volume access modes                                   | `["ReadWriteOnce"]` |
| `persistence.size`         | Persistent Volume size (extstore uses 90% of this)               | `8Gi`               |
| `persistence.selector`     | Selector to match existing PV                                    | `{}`                |
| `persistence.mountPath`    | Path to mount the volume (used for extstore path)                | `/data`             |

**Note:** When persistence is enabled, extstore is automatically configured.
See [Using Extstore](#using-extstore-persistent-disk-backed-cache) section for details.

### Deployment Parameters

| Parameter                         | Description                               | Default           |
|-----------------------------------|-------------------------------------------|-------------------|
| `command`                       | Override default container command        | `[]`            |
| `extraArgs`                     | Additional command line arguments         | `[]`            |
| `podLabels`                     | Extra labels for Memcached pods           | `{}`            |
| `podAnnotations`                | Annotations for Memcached pods            | `{}`            |
| `podManagementPolicy`           | StatefulSet Pod Management Policy         | `Parallel`      |
| `priorityClassName`             | Memcached pods' priorityClassName         | `""`            |
| `schedulerName`                 | Name of the k8s scheduler                 | `""`            |
| `terminationGracePeriodSeconds` | Seconds pod needs to terminate gracefully | `30`            |
| `updateStrategy.type`           | StatefulSet strategy type                 | `RollingUpdate` |

### Autoscaling Parameters

| Parameter                    | Description                          | Default   |
|------------------------------|--------------------------------------|-----------|
| `autoscaling.enabled`      | Enable Horizontal Pod Autoscaler     | `false` |
| `autoscaling.minReplicas`  | Minimum number of replicas           | `3`     |
| `autoscaling.maxReplicas`  | Maximum number of replicas           | `6`     |
| `autoscaling.targetCPU`    | Target CPU utilization percentage    | `50`    |
| `autoscaling.targetMemory` | Target Memory utilization percentage | `50`    |

### Pod Scheduling Parameters

| Parameter                     | Description                             | Default  |
|-------------------------------|-----------------------------------------|----------|
| `podAffinityPreset`         | Pod affinity preset (soft or hard)      | `""`   |
| `podAntiAffinityPreset`     | Pod anti-affinity preset (soft or hard) | `soft` |
| `nodeAffinityPreset.type`   | Node affinity preset type               | `""`   |
| `nodeAffinityPreset.key`    | Node label key to match                 | `""`   |
| `nodeAffinityPreset.values` | Node label values to match              | `[]`   |
| `affinity`                  | Affinity for pod assignment             | `{}`   |
| `nodeSelector`              | Node labels for pod assignment          | `{}`   |
| `tolerations`               | Tolerations for pod assignment          | `[]`   |
| `topologySpreadConstraints` | Topology Spread Constraints             | `[]`   |

### Health Check Parameters

| Parameter                              | Description                    | Default   |
|----------------------------------------|--------------------------------|-----------|
| `livenessProbe.enabled`              | Enable livenessProbe           | `true`  |
| `livenessProbe.initialDelaySeconds`  | Initial delay seconds          | `30`    |
| `livenessProbe.periodSeconds`        | Period seconds                 | `10`    |
| `livenessProbe.timeoutSeconds`       | Timeout seconds                | `5`     |
| `livenessProbe.failureThreshold`     | Failure threshold              | `6`     |
| `livenessProbe.successThreshold`     | Success threshold              | `1`     |
| `readinessProbe.enabled`             | Enable readinessProbe          | `true`  |
| `readinessProbe.initialDelaySeconds` | Initial delay seconds          | `5`     |
| `readinessProbe.periodSeconds`       | Period seconds                 | `5`     |
| `readinessProbe.timeoutSeconds`      | Timeout seconds                | `3`     |
| `readinessProbe.failureThreshold`    | Failure threshold              | `6`     |
| `readinessProbe.successThreshold`    | Success threshold              | `1`     |
| `startupProbe.enabled`               | Enable startupProbe            | `false` |
| `customLivenessProbe`                | Custom livenessProbe override  | `{}`    |
| `customReadinessProbe`               | Custom readinessProbe override | `{}`    |
| `customStartupProbe`                 | Custom startupProbe override   | `{}`    |

### Resource Parameters

| Parameter                     | Description     | Default   |
|-------------------------------|-----------------|-----------|
| `resources.limits`          | Resource limits | `{}`    |
| `resources.requests.memory` | Memory request  | `256Mi` |
| `resources.requests.cpu`    | CPU request     | `250m`  |

### Security Context Parameters

| Parameter                                             | Description                       | Default            |
|-------------------------------------------------------|-----------------------------------|--------------------|
| `podSecurityContext.enabled`                        | Enable pod Security Context       | `true`           |
| `podSecurityContext.fsGroup`                        | Pod Security Context fsGroup      | `1001`           |
| `podSecurityContext.seccompProfile.type`            | Seccomp profile type              | `RuntimeDefault` |
| `containerSecurityContext.enabled`                  | Enable container Security Context | `true`           |
| `containerSecurityContext.runAsUser`                | Container runAsUser               | `11211`          |
| `containerSecurityContext.runAsNonRoot`             | Container runAsNonRoot            | `true`           |
| `containerSecurityContext.allowPrivilegeEscalation` | Allow privilege escalation        | `false`          |
| `containerSecurityContext.capabilities.drop`        | Capabilities to drop              | `["ALL"]`        |
| `containerSecurityContext.readOnlyRootFilesystem`   | Read-only root filesystem         | `true`           |

### Extra Configuration Parameters

| Parameter              | Description                            | Default |
|------------------------|----------------------------------------|---------|
| `extraEnvVars`       | Array with extra environment variables | `[]`  |
| `extraEnvVarsCM`     | ConfigMap with extra env vars          | `""`  |
| `extraEnvVarsSecret` | Secret with extra env vars             | `""`  |
| `lifecycleHooks`     | Lifecycle hooks for containers         | `{}`  |
| `extraVolumes`       | Extra volumes for pods                 | `[]`  |
| `extraVolumeMounts`  | Extra volume mounts for containers     | `[]`  |
| `sidecars`           | Add additional sidecar containers      | `[]`  |
| `initContainers`     | Add additional init containers         | `[]`  |

### ServiceAccount Parameters

| Parameter                                       | Description                | Default   |
|-------------------------------------------------|----------------------------|-----------|
| `serviceAccount.create`                       | Create ServiceAccount      | `true`  |
| `serviceAccount.name`                         | ServiceAccount name        | `""`    |
| `serviceAccount.automountServiceAccountToken` | Auto mount token           | `false` |
| `serviceAccount.annotations`                  | ServiceAccount annotations | `{}`    |

### Service Parameters

| Parameter                            | Description                  | Default       |
|--------------------------------------|------------------------------|---------------|
| `service.type`                     | Kubernetes Service type      | `ClusterIP` |
| `service.ports.memcached`          | Memcached service port       | `11211`     |
| `service.nodePorts.memcached`      | Node port for Memcached      | `""`        |
| `service.sessionAffinity`          | Session affinity             | `None`      |
| `service.sessionAffinityConfig`    | Session affinity config      | `{}`        |
| `service.clusterIP`                | Service Cluster IP           | `""`        |
| `service.loadBalancerIP`           | Service Load Balancer IP     | `""`        |
| `service.loadBalancerSourceRanges` | Load Balancer sources        | `[]`        |
| `service.externalTrafficPolicy`    | External traffic policy      | `Cluster`   |
| `service.annotations`              | Service annotations          | `{}`        |
| `service.extraPorts`               | Extra ports to expose        | `[]`        |
| `service.headless.annotations`     | Headless service annotations | `{}`        |

### Metrics Parameters

| Parameter                                    | Description                                   | Default                     |
|----------------------------------------------|-----------------------------------------------|-----------------------------|
| `metrics.enabled`                          | Enable Prometheus exporter sidecar            | `false`                   |
| `metrics.image.registry`                   | Exporter image registry                       | `docker.io`               |
| `metrics.image.repository`                 | Exporter image repository                     | `prom/memcached-exporter` |
| `metrics.image.tag`                        | Exporter image tag                            | `v0.14.4`                 |
| `metrics.image.pullPolicy`                 | Exporter image pull policy                    | `IfNotPresent`            |
| `metrics.containerPort`                    | Exporter container port                       | `9150`                    |
| `metrics.resources.limits`                 | Exporter resource limits                      | `{}`                      |
| `metrics.resources.requests`               | Exporter resource requests                    | `{}`                      |
| `metrics.containerSecurityContext.enabled` | Enable exporter Security Context              | `true`                    |
| `metrics.service.type`                     | Exporter service type                         | `ClusterIP`               |
| `metrics.service.port`                     | Exporter service port                         | `9150`                    |
| `metrics.serviceMonitor.enabled`           | Create ServiceMonitor for Prometheus Operator | `false`                   |
| `metrics.serviceMonitor.namespace`         | ServiceMonitor namespace                      | `""`                      |
| `metrics.serviceMonitor.interval`          | Scrape interval                               | `30s`                     |
| `metrics.serviceMonitor.scrapeTimeout`     | Scrape timeout                                | `""`                      |

### RBAC Parameters

| Parameter          | Description                      | Default  |
|--------------------|----------------------------------|----------|
| `rbac.create`    | Create RBAC resources            | `true` |
| `rbac.rules`     | Additional rules for ClusterRole | `[]`   |
| `rbac.roleRules` | Additional rules for Role        | `[]`   |

### Network Policy Parameters

| Parameter                      | Description                   | Default         |
|--------------------------------|-------------------------------|-----------------|
| `networkPolicy.enabled`      | Enable NetworkPolicy          | `false`       |
| `networkPolicy.allowIngress` | Allow inbound traffic         | `true`        |
| `networkPolicy.allowEgress`  | Allow outbound traffic        | `false`       |
| `networkPolicy.podSelector`  | PodSelector for NetworkPolicy | `{}`          |
| `networkPolicy.ingress`      | Array of ingress rules        | See values.yaml |
| `networkPolicy.egress`       | Array of egress rules         | See values.yaml |

For a complete list of all parameters with detailed comments, please refer to the [values.yaml](values.yaml) file.

## Examples

### Basic Installation

```bash
helm install my-memcached ./memcached
```

### With Custom Memory Limit

```bash
helm install my-memcached ./memcached \
--set extraArgs[0].name=max-memory \
--set extraArgs[0].value=512
```

### With Metrics Enabled

```bash
helm install my-memcached ./memcached \
--set metrics.enabled=true \
--set metrics.serviceMonitor.enabled=true
```

### High Availability Setup

```bash
helm install my-memcached ./memcached \
--set replicaCount=3 \
--set podAntiAffinityPreset=hard \
--set resources.requests.memory=512Mi
```

### With Persistence

```bash
helm install my-memcached ./memcached \
--set persistence.enabled=true \
--set persistence.size=10Gi
```

## Using Extstore (Persistent Disk-Backed Cache)

Memcached's extstore feature allows extending the cache beyond available RAM by using disk storage. This chart
automatically configures extstore when persistence is enabled.

### Automatic Extstore Configuration

When you enable persistence, the chart automatically:

1. Calculates extstore size as 90% of `persistence.size` (to allow filesystem overhead)
2. Sets `ext_path` to `{persistence.mountPath}/extstore:{calculated_size}G`
3. Adds `ext_wbuf_size=16` for optimal write performance
4. Mounts the persistent volume at the specified path

### Example: Enabling Extstore

```bash
helm install my-memcached ./memcached \
--set persistence.enabled=true \
--set persistence.size=100Gi \
--set memcached.allocatedMemory=2048
```

This will configure:

- 2GB RAM cache (`allocatedMemory`)
- ~90GB disk-backed cache (extstore, automatically calculated)
- Total effective cache: ~92GB

### Advanced Extstore Options

You can add additional extstore options via `memcached.extraExtendedOptions`:

```bash

# Increase IO threads for better performance on fast SSDs

helm install my-memcached ./memcached \
--set persistence.enabled=true \
--set persistence.size=100Gi \
--set memcached.extraExtendedOptions="ext_threads=4"
```

Available extstore options:

- `ext_threads`: Number of IO threads (default: 1)
- `ext_item_size`: Minimum item size for extstore
- `ext_item_age`: Minimum age before moving to extstore
- `ext_max_sleep`: Max sleep time for IO threads (microseconds)
- `ext_recache_rate`: Rate to recache items (items/sec)

**Note:** Do not manually specify `ext_path` or `ext_wbuf_size` in `extraExtendedOptions` - these are automatically
configured from persistence settings.

## Accessing Memcached

After installation, Memcached will be available at:

```
<release-name>-memcached-headless.<namespace>.svc.cluster.local:11211
```

For a non-headless service:

```
<release-name>-memcached.<namespace>.svc.cluster.local:11211
```

## Security

This chart implements several security best practices:

- Runs as non-root user (UID 11211)
- Read-only root filesystem
- Drops all capabilities
- Disabled privilege escalation
- Security context enabled by default

## License

This Helm chart is open source and available under the MIT license.

## Memcached License

Memcached is released under the BSD 3-clause license.
See [Memcached license](https://github.com/memcached/memcached/blob/master/LICENSE) for details.
