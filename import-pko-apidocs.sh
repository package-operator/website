#!/usr/bin/env bash

# This script copies the api-reference.md from package-operator given as arg 1

set -euo pipefail

cat << 'EOF' > ./content/en/docs/api_reference/package-operator-api.md
---
title: "API Reference"
draft: false
images: []
weight: 700
toc: false
---

The Package Operator APIs are an extension of the [Kubernetes API](https://kubernetes.io/docs/reference/using-api/api-overview/) using `CustomResourceDefinitions`. These new APIs can be interacted with like any other Kubernetes object using e.g. `kubectl`.

APIs follow the same API versioning guidelines as the main Kubernetes project.

{{< details "Versioning principles." >}}
_Taken from the [Kubernetes API versioning documentation](https://kubernetes.io/docs/reference/using-api/#api-versioning):_

- **Alpha**
  - The version names contain alpha (for example, `v1alpha1`).
  - The software may contain bugs. Enabling a feature may expose bugs. A feature may be disabled by default.
  - The support for a feature may be dropped at any time without notice.
  - The API may change in incompatible ways in a later software release without notice.
  - The software is recommended for use only in short-lived testing clusters, due to increased risk of bugs and lack of long-term support.

- **Beta**
  - The version names contain beta (for example, `v2beta3`).
  - The software is well tested. Enabling a feature is considered safe. Features are enabled by default.
  - The support for a feature will not be dropped, though the details may change.
  - The schema and/or semantics of objects may change in incompatible ways in a subsequent beta or stable release. When this happens, migration instructions are provided. Schema changes may require deleting, editing, and re-creating API objects. The editing process may not be straightforward. The migration may require downtime for applications that rely on the feature.
  - The software is not recommended for production uses. Subsequent releases may introduce incompatible changes. If you have multiple clusters which can be upgraded independently, you may be able to relax this restriction.

- **Stable**
  - The version name is `vX` where `X` is an integer.
  - The stable versions of features appear in released software for many subsequent versions.
{{< /details >}}

### Group versions
- [package-operator.run/v1alpha1](#package-operatorrunv1alpha1)\
- [manifests.package-operator.run/v1alpha1](#manifestspackage-operatorrunv1alpha1)

EOF

cat $1 >> ./content/en/docs/api_reference/package-operator-api.md
