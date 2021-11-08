#!/bin/bash

k3d cluster create fredcorp --image ixxel/k3s:v1.22.3-k3s1-alpine314 \
	                    -p "5080:80@loadbalancer" \
			            -p "5443:443@loadbalancer" \
			            --volume "/home/fred/k3s-config/:/var/lib/rancher/k3s/server/manifests/" \
						--servers=2 \
			            --k3s-arg "--tls-san 192.168.0.150@server:*"
