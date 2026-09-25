[![Helm](https://img.shields.io/badge/helm-3.18+-blue.svg)](https://helm.sh/)
[![Kubernetes](https://img.shields.io/badge/kubernetes-1.28+-blue.svg)](https://kubernetes.io/)
[![License Apache2](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0)
<a href="https://okdp.io">
<img src="https://okdp.io/logos/okdp-notext.svg" height="20px" style="margin: 0 2px;" />
</a>

# OKDP Helm Handbook

Deployment guide and OKDP-specific Helm values for installing the platform components with plain `helm install`, on any Kubernetes cluster, without the OKDP Control Plane.

## Why this project

OKDP is a set of upstream and OKDP Helm charts. Installing them by hand means knowing which chart versions go together, which values wire the components to each other, and in which order to install them. This repository gives that information as plain Helm values and an ordered install guide, for platform engineers who run their own tooling or integrate OKDP components into an existing cluster.

## What the project does

- **Prerequisites umbrella chart** (`modules/prerequisites`): the infrastructure the platform needs on a local cluster (tools, certificates, ingress, DNS, PostgreSQL, secrets, identity), each one a chart dependency disabled by default and enabled per environment.
- **Apps** (`modules/apps`): one directory per data service, with its values and a README listing the contract inputs (database, S3, OIDC, ingress, certificates) to replace on another cluster.
- **Installation guide**: the ordered sequence of `helm install` from an empty cluster to the example workloads.

The values are the ones the [OKDP sandbox](https://github.com/OKDP/okdp-sandbox) runs, taken from [sandbox-dependencies](https://github.com/OKDP/sandbox-dependencies) for the prerequisites and [platform-packages](https://github.com/OKDP/platform-packages) for the data services, at the same chart versions.

> The prerequisites chart is an example for testing and local development. On a real cluster, bring your own ingress, certificates, database, identity provider and secret manager, and fill the contract inputs each app documents. Do not use it for production.

## Requirements

- a Kubernetes cluster, 1.28 or later; the sandbox values target a local [Kind](https://kind.sigs.k8s.io/) cluster
- [Helm](https://helm.sh/) 3.18 or later
- kubectl

### Toolchain tested

| Tool | Version |
|---|---|
| Kubernetes (Kind) | `1.30.0` |
| Kind | `0.23.0` |
| Helm CLI | `3.18.4` |

## Repository layout

```
modules/
├── prerequisites/            umbrella chart of the infrastructure the platform needs
│   ├── Chart.yaml            every prerequisite declared as a dependency, disabled by default
│   ├── values.yaml           defaults
│   ├── values/sandbox.yaml   values of the sandbox environment
│   ├── values/pass-1.yaml    overlays of the first and second install passes
│   ├── values/pass-2.yaml
│   ├── ci/                   one values file per module, to install it alone
│   └── README.md             install stages, one section per prerequisite
└── apps/                     one directory per data service, values and README
```

## Installation

1. Prerequisites: follow [modules/prerequisites/README.md](modules/prerequisites/README.md).
2. Apps: follow [modules/apps/README.md](modules/apps/README.md).

## Contributing & License

One pull request per module; chart versions stay aligned with the sandbox. Contributions follow the [OKDP contribution guide](https://github.com/OKDP/.github/blob/main/CONTRIBUTING.md). Released under the [Apache License 2.0](LICENSE).

---

**Built 🚀 for the OKDP Community**
<a href="https://okdp.io">
  <img src="https://okdp.io/logos/okdp-notext.svg" height="20px" style="margin: 0 2px;" />
</a>
