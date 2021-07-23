# k3s
General repository for k3s/k3d infrastructures

Installing vault with helm :
```shell
helm upgrade -i vault --namespace vault vault/ --set ui.enabled=true --set server.ingress.enabled=true --set server.ingress.tls[0].hosts[0]=vault.fredcorp.com --set server.ingress.hosts[0].host=vault.fredcorp.com
```
