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

_Not documented yet._

### identity

- **Role**: [Keycloak](https://www.keycloak.org/) 26.1, the OpenID Connect provider of the platform, at `https://keycloak.okdp.sandbox`. Its master realm is provisioned at install time by keycloak-config-cli: the sandbox users (bob, mark, nina, grace, alice, eve, adm and the service accounts), the realm roles, a `groups` client scope that maps realm roles into a `groups` claim, and one client per service (console, Superset, JupyterHub, Trino, Spark history, Polaris, Airflow, the service accounts). Admin console: `admin` / `admin`, sandbox credentials to change anywhere else.
- **Why**: every web interface and API of the platform authenticates against it. The data services reference its issuer `https://keycloak.okdp.sandbox/realms/master`, their client id and secret.
- **Depends on**: database-server (the `keycloak` database), local-secrets-provider (`creds-keycloak-db`), ingress, and the cert-manager issuers for the TLS certificate, hence pass 3.
- **Source**: the sandbox definition [keycloak](https://github.com/OKDP/sandbox-dependencies/tree/main/packages/system/keycloak): Bitnami chart keycloak 24.4.11 with the OKDP images of Keycloak and keycloak-config-cli (`allowInsecureImages` because they are not Bitnami builds). The realm JSON is the sandbox one, with the ingress suffix written in. One value is added: `externalDatabase.existingSecret` points the chart at the credentials Secret, because the chart otherwise generates a database password of its own and refuses to during an upgrade; the sandbox installs Keycloak as a release of its own and never meets that case.
- **Install**: `tags.keycloak` in `values/sandbox.yaml`, third pass. Chart-testing does not cover it: it needs the database of the second pass.
- **Verify**:

  ```sh
  kubectl get statefulset prerequisites-keycloak -n okdp-system   # 1/1; the realm import job is a hook, deleted once it succeeds
  kubectl get certificate -n okdp-system                          # keycloak.okdp.sandbox-tls READY
  kubectl port-forward svc/prerequisites-ingress-nginx-controller -n okdp-system 8443:443 &
  curl -sk --resolve keycloak.okdp.sandbox:8443:127.0.0.1 https://keycloak.okdp.sandbox:8443/realms/master | head -c 60
  # {"realm":"master","public_key":"...
  TOKEN=$(curl -sk --resolve keycloak.okdp.sandbox:8443:127.0.0.1 -d client_id=admin-cli -d username=admin -d password=admin -d grant_type=password     https://keycloak.okdp.sandbox:8443/realms/master/protocol/openid-connect/token | jq -r .access_token)
  curl -sk --resolve keycloak.okdp.sandbox:8443:127.0.0.1 -H "Authorization: Bearer $TOKEN"     'https://keycloak.okdp.sandbox:8443/admin/realms/master/users?max=50' | jq -r '[.[].username] | join(" ")'
  # adm admin alice bob eve grace mark nina and the three svc- accounts
  kill %1
  ```
