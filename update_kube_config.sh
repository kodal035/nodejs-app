#!/bin/bash
while ! minikube status | grep -q 'host: Running'; do sleep 5; done
curl -L -o /usr/local/bin/update_kube_config.sh https://github.com/kodal035/nodejs-app/raw/main/scripts/update_kube_config.sh
chmod +x /usr/local/bin/update_kube_config.sh
/usr/local/bin/update_kube_config.sh
