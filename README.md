# k3s
General repository for k3s/k3d infrastructures

## Deploying K3S

K3S use the `/var/lib/rancher/k3s/server/manifests` at startup, and apply yaml files found in it. So you can add the differents kubernetes objects you want inside this directory and it's dynamically created by k3s.

The best way to do it is to share the volume on the host with the following k3d command :

```shell
k3d cluster create fredcorp --image ixxel/k3s:v1.21.2-k3s1-alpine314 -p "5080:80@loadbalancer" -p "5443:443@loadbalancer" --volume "/home/fred/k3s-config/:/var/lib/rancher/k3s/server/manifests/"
```

## Exposing Traefik dashboard

To expose Traefik dashboard on HTTPS (websecure) port, you can create the following `IngressRoute`, or copy it inside the k3s manifest directory :

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: traefik-dashboard
  namespace: kube-system
spec:
  entryPoints:
  - websecure
  routes:
  - kind: Rule
    match: Host(`traefik.fredcorp.com`)
    services:
    - kind: TraefikService
      name: api@internal
```

## HTTPS redirection

To force HTTPS redirection, you can create a `Middleware` traefik object and a specific `IngressRoute` object to enable this rule

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: middle-redirect-http
  namespace: kube-system
spec:
  redirectScheme:
    scheme: https
    permanent: true
```

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: ingress-redirect-http
  namespace: kube-system
spec:
  entryPoints:
  - web
  routes:
  - kind: Rule
    match: hostregexp(`{host:.+}`)
    priority: 50
    middlewares:
    - name: middle-redirect-http
      namespace: kube-system
    services:
    - name: traefik
      port: 443
      namespace: kube-system
```

It's important to set a priority, to make sure this rule will be used first before any other rule.

## Default TLS certificate

Traefik handles TLS encryption by default with an auto generated certificate. If you want to delegate TLS encryption to your service, and create passthrough encryption, you need to use `IngressRouteTCP`.

In this case we want to replace the default certificate of the Traefik instance. First you need to generate a secrete :

```shell
kubectl create secret tls traefik-tls --key="certs/private.key" --cert="certs/cert.crt"
```

And the create a `TLSStore` Traefik object referencing your secret :

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: TLSStore
metadata:
  name: default
  namespace: kube-system
spec:
  defaultCertificate:
    secretName: traefik-tls
```

Traefik will automatically use the secret referenced in the `TLSStore` object named `default`.

## Using TLSStore secret in your different services

If you want your different services to use a secret defined in a `TLSSore` object, use the following syntax :

```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: ingress-vault
  namespace: kube-system
spec:
  entryPoints:
  - web
  - websecure
  routes:
  - kind: Rule
    match: Host(`vault.fredcorp.com`)
    services:
    - name: vault-ui
      port: 8200
      namespace: vault
  tls:
    store:
      name: default
  ```

Installing vault with helm :
```shell
helm upgrade -i vault --namespace vault vault/ --set ui.enabled=true --set server.ingress.enabled=true --set server.ingress.tls[0].hosts[0]=vault.fredcorp.com --set server.ingress.hosts[0].host=vault.fredcorp.com
```
