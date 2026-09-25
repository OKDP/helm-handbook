# JupyterHub

[JupyterHub](https://jupyter.org/hub) on Kubernetes with the OKDP Jupyter images: installed with the minimum of prerequisites first, then extended one dependency at a time, each one an overlay of values added with one more `-f`.

## Minimal install

The cluster only needs a default StorageClass, for the hub database and the home directory of each user. No identity provider, no ingress, no TLS, no database server, no object store.

```sh
helm repo add jupyterhub https://hub.jupyter.org/helm-chart/
helm install jupyterhub jupyterhub/jupyterhub --version 4.3.3 \
  -f modules/apps/jupyterhub/values/minimal.yaml \
  -n jupyterhub --create-namespace --wait
kubectl port-forward svc/proxy-public -n jupyterhub 8080:80
```

Open http://localhost:8080 and sign in with any user name and the password `okdp-sandbox`. The first server takes a few minutes: the notebook image is pulled at that moment.

What the minimum keeps from the sandbox: the chart version, the OKDP scientific Python image, the root start that hands the home directory over to the user, no image pre-puller, no culling, no user scheduler.

## Dependencies, one overlay each

| Dependency | What it adds | Overlay | Needs on the cluster |
|---|---|---|---|
| PostgreSQL | the hub database on a server instead of sqlite on a volume | `values/postgresql.yaml` | a database `jupyterhub` owned by a role `jupyterhub` on the platform PostgreSQL |
| Ingress | a host name instead of `port-forward` | `values/ingress.yaml` | an ingress controller of class `nginx`, the host name resolving to it |
| TLS certificate | HTTPS on that host | `values/tls.yaml` | cert-manager and the `default-issuer` ClusterIssuer |
| OIDC identity provider | the platform accounts and roles instead of a shared password | `values/oidc.yaml` | Keycloak reachable by name from the cluster, a client `jupyterhub` with `https://jupyterhub.okdp.sandbox/hub/oauth_callback` as redirect URI, and the Secret `jupyterhub-oidc` described in the overlay |
| S3 object store | the file browser and the datasets of the notebooks | `values/s3.yaml`, to come | an S3 endpoint and credentials |
| Spark on Kubernetes | the PySpark kernels and the Spark images | `values/spark.yaml`, to come | the Spark operator and its RBAC |

The overlays stack in this order, each one on top of the previous ones:

```sh
helm upgrade jupyterhub jupyterhub/jupyterhub --version 4.3.3 \
  -f modules/apps/jupyterhub/values/minimal.yaml \
  -f modules/apps/jupyterhub/values/postgresql.yaml \
  -f modules/apps/jupyterhub/values/ingress.yaml \
  -f modules/apps/jupyterhub/values/tls.yaml \
  -f modules/apps/jupyterhub/values/oidc.yaml \
  -n jupyterhub --wait
```

With the oidc overlay, https://jupyterhub.okdp.sandbox sends straight to Keycloak; the sandbox users (`bob`, `mark`, `alice`...) sign in with their own password, and `platform_admin` is the admin role of the hub.

## Verify

The minimum:

```sh
kubectl get pods -n jupyterhub                                   # hub and proxy Running
# sign in as "test" from the browser and start the server, then:
kubectl get pod jupyter-test -n jupyterhub -o jsonpath='{.status.phase} {.spec.containers[0].image}{"\n"}'
# Running quay.io/okdp/jupyter/scipy-notebook:python-3.12.12-hub-5.4.2-lab-4.5.0
kubectl get pvc claim-test -n jupyterhub                         # Bound, the home directory
kubectl exec jupyter-test -n jupyterhub -- ls -ld /home/test     # owned by test
```

Each overlay:

```sh
# postgresql: the hub tables are on the server, the sqlite volume is gone
kubectl exec cnpg-postgresql-1 -n okdp-system -c postgres -- psql -U postgres -d jupyterhub -tAc "select count(*) from information_schema.tables where table_schema='public'"   # 17
kubectl get pvc hub-db-dir -n jupyterhub                         # NotFound
# ingress: the host answers through the controller
kubectl get ingress jupyterhub -n jupyterhub                     # class nginx, host jupyterhub.okdp.sandbox
# tls: the certificate is issued and http redirects to https
kubectl get certificate jupyterhub-tls -n jupyterhub             # READY True
curl -sk -o /dev/null -w '%{http_code}\n' https://jupyterhub.okdp.sandbox/hub/login     # 200
curl -s -o /dev/null -w '%{http_code}\n' http://jupyterhub.okdp.sandbox/hub/login       # 308
# oidc: the login page hands over to Keycloak
curl -sk -o /dev/null -w '%{redirect_url}\n' https://jupyterhub.okdp.sandbox/hub/oauth_login   # https://keycloak.okdp.sandbox/realms/master/protocol/openid-connect/auth?...
```

Without a browser, a hub token drives the same steps through the API once the user has signed in once. The token must be created against the hub database, so with the hub configuration file:

```sh
TOKEN=$(kubectl exec deploy/hub -n jupyterhub -- sh -c 'jupyterhub token bob -f /usr/local/etc/jupyterhub/jupyterhub_config.py' | tail -1)
curl -sk -X POST -H "Authorization: token $TOKEN" https://jupyterhub.okdp.sandbox/hub/api/users/bob/server      # 202
curl -sk -X POST -H "Authorization: token $TOKEN" -H 'Content-Type: application/json' \
  -d '{"name":"python3"}' https://jupyterhub.okdp.sandbox/user/bob/api/kernels                                  # a kernel id
curl -sk -X DELETE -H "Authorization: token $TOKEN" https://jupyterhub.okdp.sandbox/hub/api/users/bob/server    # 204
```

## Images

The three images the module pulls, whatever the overlays, listed in `images.txt` for mirroring:

```
quay.io/jupyterhub/configurable-http-proxy:5.2.0
quay.io/jupyterhub/k8s-hub:4.3.3
quay.io/okdp/jupyter/scipy-notebook:python-3.12.12-hub-5.4.2-lab-4.5.0
```

## Source

The sandbox definition [platform-packages/packages/services/jupyterhub](https://github.com/OKDP/platform-packages/tree/main/packages/services/jupyterhub), same chart and image versions, same OIDC wiring. The sandbox installs everything the table above lists; this module starts from the other end.
