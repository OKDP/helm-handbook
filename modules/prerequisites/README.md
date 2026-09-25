[![Helm](https://img.shields.io/badge/helm-3+-blue.svg)](https://helm.sh/)
[![Kubernetes](https://img.shields.io/badge/kubernetes-1.19+-blue.svg)](https://kubernetes.io/)
[![License Apache2](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0)

# Prerequisites umbrella chart

A Helm chart for installing OKDP prerequisites.

## Installing the chart

To install the chart with the release name `prerequisites`:

```sh
$ helm dependency update modules/prerequisites/
$ helm install prerequisites modules/prerequisites
```

## Uninstalling the chart `prerequisites`

```sh
$ helm uninstall prerequisites
```
