# JupyterHub

[JupyterHub](https://jupyter.org/hub) on Kubernetes with the OKDP Jupyter images: installed with the minimum of prerequisites first, then extended one dependency at a time.

## Minimal install

The cluster only needs a default StorageClass, for the hub database and the home directory of each user. No identity provider, no ingress, no TLS, no database server, no object store.

```sh
helm repo add jupyterhub https://hub.jupyter.org/helm-chart/
helm install jupyterhub jupyterhub/jupyterhub --version 4.3.3 \
  -f modules/apps/jupyterhub/values/minimal.yaml \
  -n jupyterhub --create-namespace --wait
kubectl port-forward svc/proxy-public -n jupyterhub 8080:80
```

Open http://localhost:8080 and sign in with any user name and the password `okdp`. The first server takes a few minutes: the notebook image is pulled at that moment.

What the minimum keeps from the sandbox: the chart version, the OKDP scientific Python image, the root start that hands the home directory over to the user, no image pre-puller, no culling, no user scheduler.

## Dependencies, one overlay each

| Dependency | What it adds | Overlay | Provided by |
|---|---|---|---|
| OIDC identity provider | the platform accounts and roles instead of a shared password | `values/oidc.yaml`, to come | identity |
| Ingress | a host name instead of `port-forward` | `values/ingress.yaml`, to come | ingress |
| TLS certificate | HTTPS on that host | `values/tls.yaml`, to come | cert-manager issuers |
| PostgreSQL | the hub database on a server instead of sqlite on a volume | `values/postgresql.yaml`, to come | database-server |
| S3 object store | the file browser and the datasets of the notebooks | `values/s3.yaml`, to come | storage |
| Spark on Kubernetes | the PySpark kernels and the Spark images | `values/spark.yaml`, to come | spark |

Each overlay is added with one more `-f` on top of `values/minimal.yaml`.

## Verify

```sh
kubectl get pods -n jupyterhub                                   # hub and proxy Running
# sign in as "test" from the browser and start the server, then:
kubectl get pod jupyter-test -n jupyterhub -o jsonpath='{.status.phase} {.spec.containers[0].image}{"\n"}'
# Running quay.io/okdp/jupyter/scipy-notebook:python-3.12.12-hub-5.4.2-lab-4.5.0
kubectl get pvc claim-test -n jupyterhub                         # Bound, the home directory
kubectl exec jupyter-test -n jupyterhub -- ls -ld /home/test     # owned by test
```

Without a browser, a hub token drives the same steps through the API once the user has signed in once:

```sh
TOKEN=$(kubectl exec deploy/hub -n jupyterhub -- sh -c 'cd /srv/jupyterhub && jupyterhub token test' | tail -1)
curl -s -X POST -H "Authorization: token $TOKEN" http://localhost:8080/hub/api/users/test/server      # 202
curl -s -X POST -H "Authorization: token $TOKEN" -H 'Content-Type: application/json' \
  -d '{"name":"python3"}' http://localhost:8080/user/test/api/kernels                                  # a kernel id
curl -s -X DELETE -H "Authorization: token $TOKEN" http://localhost:8080/hub/api/users/test/server    # 204
```

## Images

The three images the minimal install pulls, listed in `images.txt` for mirroring:

```
quay.io/jupyterhub/configurable-http-proxy:5.2.0
quay.io/jupyterhub/k8s-hub:4.3.3
quay.io/okdp/jupyter/scipy-notebook:python-3.12.12-hub-5.4.2-lab-4.5.0
```

## Source

The sandbox definition [platform-packages/packages/services/jupyterhub](https://github.com/OKDP/platform-packages/tree/main/packages/services/jupyterhub), same chart and image versions. The sandbox installs everything the table above lists; this module starts from the other end.
