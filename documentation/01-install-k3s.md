# Installing k3s

## k3s cluster installation
Create the cluster and expose the required ports:

```bash
k3d cluster create fredcorp --image ixxel/k3s:v1.21.2-k3s1-alpine314 \
                            -p "5080:80@loadbalancer" \
                            -p "5443:443@loadbalancer" \
                            --volume "/home/fred/k3s-config/:/var/lib/rancher/k3s/server/manifests/" \
                            --k3s-server-arg "--tls-san 192.168.0.150"
```

The `--tls-san` option is used to allow remote kubectl commands to the VM hosting your docker k3s image.

## install the NFS client provisioner

Add helm repo :

```bash
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
helm repo update
helm fetch --untar nfs-subdir-external-provisioner/nfs-subdir-external-provisioner
```

install the provisionner with `delete` policy first :

```bash
helm upgrade -i nfs-ext-provider nfs-subdir-external-provisioner/ -n nfs --set nfs.server=192.168.0.151 \
                                                                         --set nfs.path=/NFS/data-k3s \
                                                                         --set storageClass.reclaimPolicy=Delete \
                                                                         --set accessModes=ReadWriteMany
```

then install a `retain` policy storageClass :

```bash
kubectl apply -f nfs-client-storage-class-retain.yaml
```

Unset the local-path SC to default and set the delete nfs SC to default :

```bash
kubectl patch storageclass nfs-client -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
```

you should have this output :

```console
[root@workstation ~]# sudo kubectl get sc
NAME                   PROVISIONER                                                      RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
nfs-client-retain      cluster.local/nfs-ext-provider-nfs-subdir-external-provisioner   Retain          Immediate              true                   2m4s
nfs-client (default)   cluster.local/nfs-ext-provider-nfs-subdir-external-provisioner   Delete          Immediate              true                   13m
local-path             rancher.io/local-path
```

## install the Vault server

Install with helm :
```bash
helm upgrade -i vault --namespace vault vault/ --set ui.enabled=true --set server.dataStorage.storageClass=nfs-client-retain --set server.dataStorage.size=5Gi
```

Unseal vault :

```bash
kubectl exec -it vault-0 -n vault -- sh
vault operator init --tls-skip-verify -key-shares=1 -key-threshold=1
vault operator unseal --tls-skip-verify SLPHOFrrVVhvnrCAyxMgpqCa0oJWCeuPvhkqC3uSv2U=
```

Then apply the vault ingressroute to the k3s manifest directory:
```bash
cp git/k3s/resources/yaml/ingressroute-vault.yaml k3s-config/
```

## Configure TLS wildcard certificate for all services

Create a Root CA / Int CA and wildcard certificate following the Vault documentation.
Once your wildcard certificate and private key are created, you need to create a kubernetes secret :

```bash
kubectl create secret tls traefik-tls --key="private.key" --cert="cert.crt" -n kube-system
```
 and then add the TLSstore to the k3s manifest directory 
 
 ```bash
 cp git/k3s/resources/yaml/tlsstore-traefik.yaml k3s-config/
```

Delete the traefik pod, and then the new pods should be using the new configured certificate (traefik, vault and other services will all use the wildcard cert).
 
 ```bash
kubectl delete pod traefik-97b44b794-42bkq -n kube-system
```


## configuration

copy traefik ingressroute yaml and https redirection files into the manifest directory :

```bash
cp git/k3s/resources/yaml/ingressroute-traefik-dashboard.yaml k3s-config/
cp git/k3s/resources/yaml/ingressroute-http-redirect.yaml k3s-config/
cp git/k3s/resources/yaml/middleware-http-redirect.yaml k3s-config/
```


