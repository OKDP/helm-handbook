[![Helm](https://img.shields.io/badge/helm-3.18+-blue.svg)](https://helm.sh/)
[![Kubernetes](https://img.shields.io/badge/kubernetes-1.28+-blue.svg)](https://kubernetes.io/)
[![License Apache2](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0)

# Prerequisites umbrella chart

Installs the infrastructure OKDP needs on a local cluster: tools, certificates, ingress, DNS, the PostgreSQL operator and database, secrets and identity. Each prerequisite is a dependency of this chart, switched on by its tag and configured in the block named after its alias, both in `values/<environment>.yaml`.

The values and chart versions are the ones the OKDP sandbox runs, defined in [sandbox-dependencies/packages/system](https://github.com/OKDP/sandbox-dependencies/tree/main/packages/system).

> Example for testing and local development. Do not use it for production.

## Installing the chart

Helm validates every manifest against the cluster before creating anything, so a custom resource is installed one pass after the chart that defines its CRD. The chart is installed in three passes, each one enabling more tags on top of the environment values:

1. the operators and controllers, and everything that needs no CRD;
2. trust-manager, whose webhook certificate is a cert-manager resource, and the database, a CloudNativePG resource;
3. the issuers and the trust bundle, cert-manager and trust-manager resources, and identity, which needs the database.

```sh
helm dependency update modules/prerequisites

helm install prerequisites modules/prerequisites \
  -f modules/prerequisites/values/sandbox.yaml \
  -f modules/prerequisites/values/pass-1.yaml \
  -n okdp-system --create-namespace --wait

helm upgrade prerequisites modules/prerequisites \
  -f modules/prerequisites/values/sandbox.yaml \
  -f modules/prerequisites/values/pass-2.yaml \
  -n okdp-system --wait

helm upgrade prerequisites modules/prerequisites \
  -f modules/prerequisites/values/sandbox.yaml \
  -n okdp-system --wait
```

## Uninstalling the chart

```sh
helm uninstall prerequisites -n okdp-system
```

## Install passes

| Pass | Prerequisite | Helm dependencies (alias and tag) | Sandbox definition |
|---|---|---|---|
| 1 | tools | reloader, replicator, secret-generator | tools |
| 1 | cert-manager | cert-manager | cert-manager |
| 1 | pg-operator | cloudnative-pg | cloudnative-pg |
| 1 | ingress | ingress-nginx | ingress-nginx |
| 1 | external-secrets | external-secrets | external-secrets |
| 1 | local-secrets-provider | local-secrets-provider | local-secrets-provider |
| 1 | dns, Kind only | coredns-patch, dns-server | coredns-patch, dns-server |
| 2 | cert-manager trust | trust-manager | cert-manager |
| 2 | database-server | cnpg-postgresql | cnpg-postgresql |
| 3 | cert-manager issuers | cert-issuers | cert-manager |
| 3 | identity | keycloak | keycloak |

## Modules

One section per prerequisite, following this template:

- **Role**: what it deploys
- **Why**: which OKDP components need it
- **Depends on**: the prerequisites that must be installed first
- **Source**: the sandbox definition it comes from, and the chart versions
- **Install**: the tags to set
- **Verify**: the command that shows it works

### tools

- **Role**: three cluster-wide utilities. [Reloader](https://github.com/stakater/Reloader) restarts the pods of a workload annotated `reloader.stakater.com/auto: "true"` when a ConfigMap or Secret it uses changes. [Replicator](https://github.com/mittwald/kubernetes-replicator) copies Secrets and ConfigMaps across namespaces, driven by the `replicator.v1.mittwald.de/replicate-to` annotation. [Secret Generator](https://github.com/mittwald/kubernetes-secret-generator) fills Secrets annotated `secret-generator.v1.mittwald.de/autogenerate` with random values.
- **Why**: generated and replicated secrets are how the sandbox hands credentials from one prerequisite to another. local-secrets-provider, database-server and identity rely on them.
- **Depends on**: nothing, first pass.
- **Source**: the sandbox definition [sandbox-dependencies/packages/system/tools](https://github.com/OKDP/sandbox-dependencies/tree/main/packages/system/tools): reloader 1.0.72, kubernetes-replicator 2.9.2, kubernetes-secret-generator 3.4.0. The sandbox installs them in the `kube-tools` namespace; here they land in the release namespace, which changes nothing for their consumers since all three are cluster-wide.
- **Install**: `tags.reloader`, `tags.replicator` and `tags.secret-generator` in `values/sandbox.yaml`.
- **Verify**:

  ```sh
  kubectl get deploy -n okdp-system
  # prerequisites-reloader, prerequisites-replicator and secret-generator are 1/1 AVAILABLE

  kubectl apply -n okdp-system -f - <<EOF
  apiVersion: v1
  kind: Secret
  metadata:
    name: generated
    annotations:
      secret-generator.v1.mittwald.de/autogenerate: password
  EOF
  kubectl get secret generated -n okdp-system -o jsonpath='{.data.password}' | base64 -d | wc -c
  # 40, the length of the generated password
  kubectl delete secret generated -n okdp-system
  ```

### cert-manager

_Not documented yet._

### pg-operator

_Not documented yet._

### ingress

_Not documented yet._

### external-secrets

_Not documented yet._

### local-secrets-provider

_Not documented yet._

### dns

_Not documented yet._

### database-server

_Not documented yet._

### identity

_Not documented yet._
