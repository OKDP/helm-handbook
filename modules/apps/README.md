# Apps

One directory per data service. The values and chart versions are the ones the OKDP sandbox runs, defined in [platform-packages/packages/services](https://github.com/OKDP/platform-packages/tree/main/packages/services).

## Layout of a service

```
modules/apps/<service>/
├── Chart.yaml            only when the service is made of several charts: an umbrella of them
├── values/sandbox.yaml   values of the sandbox environment
└── README.md             chart sources and versions, contract inputs, install and verification
```

A service with a single chart is installed straight from its upstream repository with the values file:

```sh
helm install <service> <repository>/<chart> --version <version> \
  -f modules/apps/<service>/values/sandbox.yaml -n <namespace> --create-namespace
```

## Contract inputs

Each service needs a few things from its surroundings: a database, an object store, an identity provider, an ingress class, a certificate issuer. Those values are written in `values/sandbox.yaml` and listed in the README of the service, so that they can be replaced on another cluster.

| Input | Sandbox value | Provided by |
|---|---|---|
| database server | host, port, database name, credentials secret | prerequisites, cnpg-postgresql |
| S3 object store | endpoint, credentials secret, buckets | an S3-compatible store, SeaweedFS in the sandbox |
| OIDC | issuer and endpoints, client id, client secret | prerequisites, keycloak |
| ingress | class `nginx`, suffix `okdp.sandbox` | prerequisites, ingress-nginx |
| certificates | cluster issuer `default-issuer` | prerequisites, cert-manager |

## Services

In install order: spark (operator, rbac, defaults), hive-metastore, trino, superset, jupyterhub, spark-history-server, polaris, airflow, then okdp-examples as the final check.
