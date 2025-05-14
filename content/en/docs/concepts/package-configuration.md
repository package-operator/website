---
title: Package Configuration
draft: false
images: []
weight: 700
toc: true
---

In the context of the Package Operator, package configuration
enables you to customize your resource deployments using templates.
This documentation will introduce you to the core concepts of
package configuration, how it works, and how you can use it to
streamline your application deployments.

## Understanding Package Configuration

You can think of package configuration as a set of customizable
knobs and switches that you can turn to adjust how your
application or operator gets deployed. Using these knobs, you can
adjust the deployment to your needs without changing the actual
code. Package configuration includes defining how you create and
customize resources using templates.

The main components involved in package configuration are:

1. **Templates**: These files have placeholders that you will
replace with values from the configuration context.
1. **Configuration Definition**: The configuration definition
specifies the structure of the configuration parameters that you
can customize when deploying a package. It provides information
about properties, data types, default values, and required or optional settings.
1. **Configuration Context**: During deployment, the configuration
context is the set of values and information used to replace
placeholders in templates. It includes details about the package, images,
configuration settings, and the environment.
The configuration context contains the values that apply to a
particular deployment, so you can tailor the package to fit your needs.

## Benefits of Package Configuration

Package configuration offers several advantages when deploying applications or operators
using the Package Operator:

* **Simplified deployment:** Package configuration streamlines the
deployment process by allowing you to define customizable values
without modifying the underlying resource templates.

* **Consistency:** With package configuration, you ensure consistency
across deployments, as you can enforce predefined configurations for
different environments.

* **Customization without code changes:** Package configuration enables
you to tailor your deployment without altering the application or
operator codebase. You can easily switch configurations for various use cases.

## Defining Package Configuration

You have the option to include a `config` section within your packages.
Define this section within the package manifest using OpenAPI
specifications. It's good practice to define values that are
essential for successful package deployment as `required`, and to set
default values where applicable. By incorporating default values, you
prevent deployment failures caused by missing mandatory values.

**NOTE:** These two solutions are mutually
exclusive. You can either mark a property as
`required` to enforce the necessity of providing
a value, thereby preventing failure, or assign a
default value to ensure success even
when no value is provided. It's important not to
use both approaches for the same property.

When creating your package, consider the essential configuration
parameters that you will need to customize. Provide default values
for properties that you can set up, but you can change them if you want to.

Here's a simple example of specifying a configuration schema in your package `manifest.yaml`:

```yaml
spec:
  config:
    openAPIV3Schema:
      properties:
        nginxImage:
          description: nginxImage is the reference to the image
          containing nginx.
          type: string
          default: "nginx:latest"
        nginxWebrootConfigmap:
          description: nginxWebrootConfigmap is the name of an
          already existing configmap in the package namespace that
          will be mounted into the nginx containers as webroot folder.
          type: string
      required:
        - nginxWebrootConfigmap
      type: object
```

This example sets the default `nginxImage` to `nginx:latest` and declares the key
`nginxWebrootConfigmap` as required.

---

Next, you add the following to the template section of your `deployment.yaml.gotmpl`:

```yaml
template:
    metadata:
      labels:
        app.kubernetes.io/name: nginx
        app.kubernetes.io/instance: "{{ .package.metadata.name }}"
    spec:
      containers:
        - name: nginx
          image: "{{ .config.nginxImage }}"
          ports:
            - containerPort: 80
          volumeMounts:
            - name: nginx-webroot
              mountPath: /usr/share/nginx/html
      volumes:
        - name: nginx-webroot
          configMap:
            name: nginx-webroot
```

---

Finally, you configure the example `package.yaml` as follows and deploy it:

``` yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-webroot
data:
  index.html: |-
    <html>
      <body>
        <h1>hi there</h1>
      </body>
    </html>
---
apiVersion: package-operator.run/v1alpha1
kind: Package
metadata:
  name: nginx-webroot
spec:
  image: quay.io/yourquayusername/nginx:tag
  config:
    nginxWebrootConfigmap: nginx-webroot
```

---

Verify the configuration by running `curl` on the deployment.

   Example:

   ```bash
    kubectl exec deploy/nginx-webroot  -- curl -s localhost
   ```

   Example Output:

   ```bash
   <html>
     <body>
       <h1>hi there</h1>
     </body>
   ```

## Examples

Let’s examine a couple more examples to illustrate how package configuration works.

### Example 1: Customizing Image Versions

Suppose you have multiple applications with different frontend and
backend images and ports. You want users to easily customize the
images and ports based on the application. Here's a step-by-step process:

1. **Create a PackageManifest** \
Define the scope and phases of your package in your `manifest.yaml`:

   ```yaml
   apiVersion: manifests.package-operator.run/v1alpha1
   kind: PackageManifest
   metadata:
     name: frontend-backend
   spec:
     scopes:
     - Namespaced
     phases:
     - name: deploy
     availabilityProbes:
     - probes:
       - condition:
           type: Available
           status: "True"
       - fieldsEqual:
           fieldA: .status.updatedReplicas
           fieldB: .status.replicas
       selector:
         kind:
           group: apps
           kind: Deployment
   ```

1. **Define Package Configuration** \
Under the `config` section, add the configuration schema for your
package to your `manifest.yaml`. Allow users define image and port versions.

   ```yaml
   config:
     openAPIV3Schema:
     properties:
       frontendImage:
          description: frontendImage is the reference to the image containing the frontend application.
          type: string
       databaseImage:
          description: backendImage is the reference to the image containing the backend application.
          type: string
       frontendPort:
          description: Port for the frontend container.
          type: integer
          default: 80
       databasePort:
          description: Port for the database container.
          type: integer
          default: 5432
     type: object
   ```

1. **Add the following to the template section of your `deployment.yaml.gotmpl`:**

   ```yaml
    template:
      metadata:
        labels:
          app.kubernetes.io/name: frontend-backend
          app.kubernetes.io/instance: "{{ .package.metadata.name }}"
      spec:
        containers:
          - name: frontend
            image: "{{ .config.frontendImage }}"
            ports:
              - containerPort: {{ .config.frontendPort }}

          - name: database
            image: "{{ .config.databaseImage }}"
            ports:
              - containerPort: {{ .config.databasePort }}
   ```

1. **Build and push your package to your image repository:**

   ```yaml
   kubectl package validate <your-template-directory>
   ```

   ```yaml
   kubectl package build -t <your-image-reference-goes-here> --push <your-template-directory>
   ```

1. **Apply Custom Configuration**

   In your Package resource, users can add values for the configured properties.
   For example:

   ```yaml
   apiVersion: package-operator.run/v1alpha1
   kind: Package
   metadata:
     name: frontend-backend-deploy
   spec:
     image: quay.io/yourquayusername/frontend-backend-deploy:v2
     config:
       // configuration for abc-app
       frontendImage: quay.io/yourquayusername/nginx:abc-appv1
       databaseImage: quay.io/yourquayusername/postgres:abc-appv14.5
       frontendPort: 8080
       databasePort: 5433
   ```

1. **Deploy the package**:

   ```yaml
    kubectl create -f package.yaml
   ```

1. **Verify the package status**:

   ```yaml
    kubectl get packages
   ```

### Example 2: Using Package Configuration in a Deployment Template with a ClusterObjectTemplate

Imagine you are an engineer responsible for managing deployments in a
Kubernetes cluster using the Package Operator. You have a package
application, and you want to streamline the stage and production
deployment process by using package configuration and [ClusterObjectTemplates](https://package-operator.run/docs/api_reference/package-operator-api#clusterobjecttemplate).

**Application Configuration**

* You have built your package application as a container image and
pushed it to a registry such as `quay.io/yourusername/frontend-deployment:v1`.
* Your deployment template (`deployment.yaml.gotmpl`) consists of Package Configuration
for app name, image, and namespace.

Example `deployment.yaml.gotmpl`:

```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: {{ .package.metadata.name }}-deployment
     namespace: "{{ .config.namespace }}"
     labels:
       app.kubernetes.io/name: "{{ .config.app }}"
       app.kubernetes.io/instance: "{{ .package.metadata.name }}"
     annotations:
       package-operator.run/phase: deploy
   spec:
     replicas: 3
     selector:
       matchLabels:
         app.kubernetes.io/name: "{{ .config.app }}"
     template:
       metadata:
         labels:
           app.kubernetes.io/name: "{{ .config.app }}"
       spec:
         containers:
         - name: "{{ .config.app }}"
           image: "{{ .config.image }}"
```

Example `manifest.yaml`:

```yaml
   apiVersion: manifests.package-operator.run/v1alpha1
   kind: PackageManifest
   metadata:
     name: my-deployment-package
   spec:
     scopes:
       - Namespaced
       - Cluster
     phases:
       - name: deploy
     availabilityProbes:
     - probes:
       - condition:
           type: Available
           status: "True"
       - fieldsEqual:
           fieldA: .status.updatedReplicas
           fieldB: .status.replicas
       selector:
         kind:
           group: apps
           kind: Deployment
     config:
       openAPIV3Schema:
         properties:
           namespace:
             description: The namespace to deploy to.
             type: string
           app:
             description: The name of the application.
             type: string
           image:
             description: The image to use for the deployment.
             type: string
         required:
           - namespace
           - app
           - image
         type: object
```

1. **Create a ConfigMap with Application Configuration:**

   Create a ConfigMap that stores the configuration data for your application.

   ```yaml
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: myapp-config
     namespace: integration
   data:
     namespace: production-namespace
     image: quay.io/yourusername/wizard:stable
     app: wizard
   ```

1. **Apply the ConfigMap to your cluster:**

   ```bash
   kubectl apply -f configmap.yaml
   ```

1. **Create a ClusterObjectTemplate:**

   Create a ClusterObjectTemplate that references the ConfigMap and
   uses it to template the PackageManifest.

   Use the following YAML and apply it:

   ```yaml
   apiVersion: package-operator.run/v1alpha1
   kind: ClusterObjectTemplate
   metadata:
     name: cool-new-app-template
     namespace: integration
   spec:
     sources:
       - apiVersion: v1
         items:
           - destination: .namespace
             key: .data.namespace
           - destination: .image
             key: .data.image
           - destination: .app
             key: .data.app
         kind: ConfigMap
         name: myapp-config
         namespace: integration
         optional: false
     template: |
       apiVersion: package-operator.run/v1alpha1
       kind: Package
       metadata:
         name: "{{ .config.name }}"
         namespace: "{{ .config.namespace }}"
       spec:
         image: "quay.io/yourusername/frontend-deployment:v1"
         config: {{toJson .config}}
   ```

1. **Apply the ClusterObjectTemplate:**

   Apply the ClusterObjectTemplate using the `kubectl apply -f clusterobjecttemplate.yaml`
   command.

   Use the `kubectl describe clusterobjecttemplates <your-template-name>` command
   to verify the ClusterObjectTemplate status.

   Example:

   ```bash
   kubectl describe clusterobjecttemplates cool-new-app-template
   ... snipped for readability
   Status:
     Conditions:
       Last Transition Time:  2023-09-09T20:17:47Z
       Message:               Unpack job succeeded
       Observed Generation:   1
       Reason:                UnpackSuccess
       Status:                True
       Type:                  Unpacked
   ```

1. **Create Packages Based on ClusterObjectTemplate:**

   When the ClusterObjectTemplate is applied, it creates Package
   objects based on the initial configuration from the ConfigMap.

   These Package objects represent your deployments.
   You can view the created Package objects using `kubectl get packages -A`
   and `kubectl get deployments -A` to view the corresponding deployments.

   Example:

   ```bash
   kubectl get packages -A
   NAMESPACE              NAME            STATUS      AGE
   production-namespace   wizard          Available   3m21s
   ```

   ```bash
   kubectl get deployments -n production-namespace
   NAME                READY   UP-TO-DATE   AVAILABLE   AGE
   wizard-deployment   3/3     3            3           5m15s
   ```

1. **Update the Application Configuration:**

   Update the configuration of your application and modify the data in the
  `myapp-config` ConfigMap.

   Example:

   ```yaml
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: myapp-config
     namespace: integration
   data:
     namespace: production-namespace
     image: quay.io/yourusername/wizard:v3
     app: wizard
   ```

1. **Apply the ConfigMap:**

   Apply the ConfigMap by issuing:
   `kubectl apply -f configmap.yaml`.

   The package status will change status to **Progressing** and then **Available**:

   Example:

     ```bash
     kubectl get packages -A
     NAMESPACE              NAME            STATUS        AGE
     production-namespace   wizard          Progressing   7m43s
     ```

   ```bash
   kubectl get packages -A
   NAMESPACE              NAME            STATUS      AGE
   production-namespace   wizard          Available   8m11s
   ```

1. **Verify the deployment:**

   Verify the deployment is using the updated image:

   ```bash
   kubectl describe deployment wizard-deployment -n production-namespace
   ...
   Pod Template:
     Labels:  app.kubernetes.io/name=wizard
     Containers:
     wizard:
      Image:        wizard:v3
      Port:         <none>
      Host Port:    <none>
      Environment:  <none>
      Mounts:       <none>
     Volumes:        <none>
   ```

1. **Update the ConfigMap for Stage Deployment:**

   To create a deployment for stage, update the ConfigMap with the details
   of the stage deployment.

   Example:

   ```yaml
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: myapp-config
     namespace: integration
   data:
     namespace: staging-namespace
     image: quay.io/yourusername/wizard:2.0.0-beta
     app: wizard
   ```

1. **Apply the ConfigMap to your cluster:**

   Apply the ConfigMap to your cluster, by issuing:

   ```bash
   kubectl apply -f configmap.yaml
   ```

   When you apply the ConfigMap, the wizard package is created in the
   staging-namespace, along with the deployments.

1. **Verify the Package object creation and deployments:**

   ```bash
   kubectl get packages -A
   NAMESPACE              NAME            STATUS      AGE
   production-namespace   wizard          Available   70m
   staging-namespace      wizard          Available   51s
   ```

   ```bash
   kubectl get deployments -A
   production-namespace      wizard-deployment          3/3     3            3           73m
   staging-namespace         wizard-deployment          3/3     3            3           4m47s

   ```

These steps guided you through deploying and updating your application using package
configuration and ClusterObjectTemplates with the Package Operator.

## Troubleshooting

### Logging Behavior

The `logLevel` configuration helps you control the verbosity of logs to aid in troubleshooting.

To increase verbosity for troubleshooting,
update the `logLevel` via the `spec.config` field of your `ClusterPackage`.
For example:

```bash
kubectl patch clusterpackage package-operator \
  --type=merge \
  -p '{"spec": {"config": {"logLevel": 1}}}'
```

**Log Level Reference:**

| `logLevel` | Output Includes                                                                 |
|------------|----------------------------------------------------------------------------------|
| `-1`       | `log.Error()` – Default level; errors logs shown. |
| `0`        | `log.Error()` and `log.Info()` – Base level of informational logs. |
| `1`        | `log.Error()`, `log.Info()`, and `log.V(1).Info()` – Adds first level of debug. |
| `2`        | Above plus `log.V(2).Info()` – includes second-level debug logs.                 |
| ...        | Increasing verbosity with higher numbers – adds `log.V(N).Info()` for N ≥ 3.     |

This setting is helpful when debugging reconciliation behavior,
unexpected resource changes, or communication issues across clusters.

### Error Messages and Troubleshooting

During the package configuration process, you may encounter common
errors such as missing or incorrectly formatted values. Here are some
troubleshooting tips:

* **Check Property Names:** Ensure that property names in your configuration
match those defined in the package manifest's configuration schema.
* **Data Type Mismatch:** Verify that the data types of configured values match
the expected types in the schema.
* **Test Framework:** Use the Package Operator [test framework](https://package-operator.run/docs/guides/packaging-an-application/#testing-templates)
to test your templates.
* **Review Logs:** Review the Package Operator manager logs using
the `kubectl logs -f package-operator-manager<pod> -n package-operator-system` command.

## Conclusion

These examples illustrate how you can leverage package configuration to provide a
streamlined and customized way to deploy applications in Kubernetes using the Package
Operator. The power of package configuration lies in its ability to abstract
and parameterize values in your resources, making deployments flexible and adaptable.
