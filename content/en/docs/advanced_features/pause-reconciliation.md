---
title: Pausing Reconciliation
weight: 2000
---

When deploying a `Package`, Package Operator automatically reconciles
all objects under it. Therefore, any changes made to the fields controlled
by Package Operator in the child objects will be reverted by the Package
Operator reconcilers.

To temporarily stop the reconciliation of these objects,
the `.spec.paused` field has been introduced to the `Package`
and `ObjectDeployment` APIs. When set to `true`, all reconciliation
of the object and its children will be stopped (except for the `.status`
field).

## 1. Pausing Mechanism

The `.spec.paused` field is propagated down the ownership chain.
Therefore, after pausing a `Package` object, the underlying `ObjectDeployment`
is paused, then finally, the `ObjectSet` is paused. As a consequence,
an `ObjectDeployment` may be individually paused only when it is not
owned by a `Package` object.

Even when paused, each object reflects its status properly. When the lowest
object in the Package Operator API chain is paused (i.e., the `ObjectSet`),
the `.status` field of the object is updated with the `Paused` condition
set to true. This condition is then propagated up to the parent objects.

To unpause the reconciliation of a `Package` or `ObjectDeployment`, simply
set the `.spec.paused` field to `false` or remove it entirely.

## 2. Pausing via the CLI

To accommodate pausing the reconciliation of `(Cluster)Package` objects without
the need for manual editing, the `pause` and `unpause` subcommands have been
added to the `kubectl package` CLI.

The command modifies the `.spec.paused` field and the waits for the object
to report the `Paused` condition. It also allows the user to provide
a message (e.g., the reason for the pause)
which will be stored in the `package-operator.run/pause-message`
annotation.

Usage:

```bash
kubectl package pause <resource>/<name> [-n <namespace>] [-m <message>]
kubectl package unpause <resource>/<name> [-n <namespace>]
```
