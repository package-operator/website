---
title: Global Image Prefix Override
weight: 2001
---

The Global Image Prefix Override feature allows using mirrored package and
workload images from a private registry without needing to rebuild the images
with new image references.

This feature solves the problem of mirroring package images that reference
other images with the [image-digest feature](/docs/guides/image-digests/)
without having to rebuild the images.

For example, this enables deployment of upstream package-operator artifacts
from private registries without rebuilding them in downstream pipelines.
This solves the previously impossible scenario where organizations needed
to mirror upstream images, because PKO's internal image digest feature insist
on referencing images by their original address.

## Implementation

Prefix overrides can be configured through either of these options supplied
to the `package-operator-manager` binary:

- Environment variable: `PKO_IMAGE_PREFIX_OVERRIDES`
- Command-line flag: `image-prefix-overrides`

Both accept mappings in `from=to` format
(e.g., `quay.io/my-org/=mirror.example.com/mirror-org/`).
A comma separataed list in the same format can also be provided
for multiple overrides. When Package Operator encounters an image reference
starting with the `from` prefix, it automatically substitutes it with the
`to` prefix while preserving the remainder of the image path.

## Usage Example

The following `mirror.sh` script demonstrates the mirroring of the images
and the modification of the bootstrap job manifests.
(Images for version v1.82.2 are mirrored from the registry namespace
`quay.io/package-operator` into the registry namespace
`quay.io/erdii-test/pko-mirror`).

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

### Image Mirroring

The `skopeo copy` commands create identical copies of all upstream
PKO package images in your private registry,
maintaining the original tags and manifests.

### Prefix Override Injection

The first `yq` command modifies the PKO_IMAGE_PREFIX_OVERRIDES environment
variable to redirect all PKO package image pulls from quay.io/package-operator/
to quay.io/erdii-test/pko-mirror/ while additionally rewriting the prefixes
of the templated image address outputs of the
[image digest feature](https://github.com/package-operator/website/blob/904d2c0a90d53e01ed59b602181d47b314925b8b/content/en/docs/guides/image-digests.md).
Example template directive: {{.images.someNamedImage}}

The pattern `original-prefix/=new-prefix/` ensures complete prefix substitution
while preserving image names and tags.

### Direct Reference Updates

The second `yq` command handles hardcoded image references that
bypass the prefix override mechanism by:

Modifying the container's `.image` field
Updating the first command-line argument in .args[0]

To ensure that all artifacts required for PKO's bootstrap procedure are
pulled correctly, it is required to reference the bootstrap job workload image
directly from the mirrored location.

The package image location also gets replaced for readability reasons.

## Deployment Process

### 1. Apply the prepared manifest on the target cluster

```bash
kubectl apply -f self-bootstrap-job.yaml
```

### 2. Monitor progress until the ClusterPackage CRD becomes available

### 3. Verification

```bash
# Verify package image source
kubectl get clusterpackage package-operator -o yaml | yq .spec.image

# Confirm manager deployment uses mirrored images
kubectl get -n package-operator-system deployment/package-operator-manager -o yaml | yq '.spec.template.spec.containers[].image'
```
