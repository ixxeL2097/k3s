# 02 - Software installation

## Heimdall

Heimdall is a very usefull tool to install and manage your infrastrucre

- https://heimdall.site/
- https://artifacthub.io/packages/helm/k8s-at-home/heimdall

```bash
helm repo add k8s-at-home https://k8s-at-home.com/charts/
helm repo update
helm fetch --untar k8s-at-home/heimdall
helm upgrade -i heimdall heimdall/ -n heimdall
```

And apply the ingressRoute for heimdall :

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: ingress-heimdall
  namespace: kube-system
spec:
  entryPoints:
  - web
  - websecure
  routes:
  - kind: Rule
    match: Host(`heimdall.fredcorp.com`)
    services:
    - name: heimdall
      port: 80
      namespace: heimdall
  tls:
    store:
      name: default
```

Move the ingressRoute to the manifests directory
```bash
cp k3s-resources/ingressroute-heimdall.yaml k3s-config/
```

if needed 
```bash
kubectl apply -f ingressroute-heimdall.yaml
```
