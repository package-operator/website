---
title: Installation
weight: 400
images: []
---

We only support a single method of installing Package Operator
at the time: [Bootstrapping Package Operator via Package Operator](#via-package-operator).

Check the latest available release at [Package Operator Releases](https://github.com/package-operator/package-operator/releases).

## Via Package Operator

Package Operator is able to bootstrap and upgrade itself using a special self-bootstrap-job.

Make sure `KUBECONFIG` is defined and the config points at your Kubernetes cluster.
Then you can deploy Package Operator to bootstrap itself:

```sh
kubectl create -f https://github.com/package-operator/package-operator/releases/latest/download/self-bootstrap-job.yaml
```

This will not install the webhook server.

## kubectl package plugin

A [kubectl plugin](https://kubernetes.io/docs/tasks/extend-kubectl/kubectl-plugins/)
named `package` is released alongside Package Operator itself to make the interaction
easier.

Follow these simple steps to install it:

1. download the `kubectl-package_*` file for local architecture from the
[releases page](https://github.com/package-operator/package-operator/releases)
2. rename it to `kubectl-package`
3. make it executable (e.g. `chmod +x kubectl-package` on Linux)
4. move it to anywhere on your `PATH`

This will allow you to issue `kubectl package ...` commands

For a more detailed explanation on how to install plugins, check the
[official documentation](https://kubernetes.io/docs/tasks/extend-kubectl/kubectl-plugins/#installing-kubectl-plugins)
