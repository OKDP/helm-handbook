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

_Not documented yet._

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

- **Role**: the platform PostgreSQL instance, a CloudNativePG `Cluster` named `cnpg-postgresql` (PostgreSQL 18, one instance, 2Gi on the `standard` storage class), with one logical `Database` per entry of the list, each owned by a role whose credentials are read from a Secret. Reachable at `cnpg-postgresql-rw.okdp-system.svc.cluster.local:5432`.
- **Why**: identity stores its state in the `keycloak` database. The data services declare their own databases the same way, in their own values.
- **Depends on**: pg-operator, whose CRDs it uses, hence pass 2, and local-secrets-provider for the owner Secret.
- **Source**: the sandbox definition [cnpg-postgresql](https://github.com/OKDP/sandbox-dependencies/tree/main/packages/system/cnpg-postgresql): chart cnpg-postgresql 0.1.0, image ghcr.io/cloudnative-pg/postgresql 18.3.
- **Install**: `tags.cnpg-postgresql` in `values/sandbox.yaml`, second pass. Chart-testing does not cover it: it cannot be installed alone without the operator CRDs. The chart also checks, at render time, that the owner Secret exists in the namespace, so `helm template` without a cluster reports it missing while `helm install` and `helm upgrade` find it.
- **Verify**:

  ```sh
  kubectl get cluster cnpg-postgresql -n okdp-system     # STATUS Cluster in healthy state
  kubectl get database keycloak -n okdp-system           # APPLIED True
  kubectl exec cnpg-postgresql-1 -n okdp-system -- psql -U postgres -tAc "select datname, pg_get_userbyid(datdba) from pg_database where datname = 'keycloak'"
  # keycloak|keycloak
  ```

### identity

_Not documented yet._
