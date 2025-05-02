---
title: Global Image Prefix Override
weight: 2001
---

The Global Image Prefix Override feature enables deployment of upstream package-operator artifacts from private registries without rebuilding them in downstream pipelines. This solves the previously impossible scenario where organizations needed to mirror upstream images while maintaining original deployment manifests.

## Implementation

Prefix overrides can be configured through either:
- Environment variable: `PKO_IMAGE_PREFIX_OVERRIDES`
- Command-line flag: `image-prefix-overrides`

Both accept mappings in `from=to` format (e.g., `quay.io/my-org/=mirror.example.com/mirror-org/`). When Package Operator encounters an image reference starting with the `from` prefix, it automatically substitutes it with the `to` prefix while preserving the remainder of the image path.

## Usage Example

The following `mirror.sh` script demonstrates a complete workflow for deploying Package Operator using mirrored images:

```bash
#!/bin/bash
set -euxo pipefail

# Mirror upstream images to private registry
skopeo copy --all \
  docker://quay.io/package-operator/package-operator-package:v1.18.2 \
  docker://quay.io/erdii-test/pko-mirror/package-operator-package:v1.18.2

skopeo copy --all \
  docker://quay.io/package-operator/package-operator-manager:v1.18.2 \
  docker://quay.io/erdii-test/pko-mirror/package-operator-manager:v1.18.2

skopeo copy --all \
  docker://quay.io/package-operator/remote-phase-manager:v1.18.2 \
  docker://quay.io/erdii-test/pko-mirror/remote-phase-manager:v1.18.2

# Download original bootstrap manifest
curl -LO https://github.com/package-operator/package-operator/releases/download/v1.18.2/self-bootstrap-job.yaml

# Apply global prefix override
yq -i 'with(
      select(.kind == "Job").spec.template.spec.containers[]
    | select(.name == "package-operator").env[]
    | select(.name == "PKO_IMAGE_PREFIX_OVERRIDES")
    ; .value = "quay.io/package-operator/=quay.io/erdii-test/pko-mirror/"
  )' self-bootstrap-job.yaml

# Update direct image references
yq -i 'with(
      select(.kind == "Job").spec.template.spec.containers[]
    | select(.name == "package-operator")
    ; (
      .image |= sub("quay.io/package-operator", "quay.io/erdii-test/pko-mirror"),
      .args[0] |= sub("quay.io/package-operator", "quay.io/erdii-test/pko-mirror")
    )
  )' self-bootstrap-job.yaml 
```

## Key Components Explained

### Image Mirroring: 
The `skopeo copy` commands create identical copies of all upstream images in your private registry, maintaining the original tags and manifests.

### Prefix Override Injection:
The first `yq` command modifies the PKO_IMAGE_PREFIX_OVERRIDES environment variable to redirect all quay.io/package-operator/ pulls to quay.io/erdii-test/pko-mirror/

The pattern `original-prefix/=new-prefix/` ensures complete path substitution while preserving image names and tags

### Direct Reference Updates:
The second `yq` command handles hardcoded image references that bypass the prefix override mechanism by:

Modifying the container's `.image` field
Updating the first command-line argument in .args[0]
  
# Deployment Process

## 1. Apply the prepared manifest on the target cluster:
```kubectl apply -f self-bootstrap-job.yaml```

## 2. Monitor progress until the ClusterPackage CRD becomes available
## 3. Verification:
```
# Verify package image source
kubectl get clusterpackage package-operator -o yaml | yq .spec.image

# Confirm manager deployment uses mirrored images
kubectl get -n package-operator-system deployment/package-operator-manager -o yaml | yq '.spec.template.spec.containers[].image'
```
The override system maintains all original functionality while transparently redirecting image pulls, enabling the enforcement of registry policies without modifying upstream deployment logic.

