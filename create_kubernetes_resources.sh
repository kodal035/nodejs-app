#!/bin/bash
while ! minikube status | grep -q 'host: Running'; do sleep 5; done
kubectl create ns jenkins
kubectl create sa jenkins -n jenkins
kubectl create rolebinding jenkins-admin-binding --clusterrole=admin --serviceaccount=jenkins:jenkins --namespace=jenkins
curl -L -o /usr/local/bin/get_kube_token.sh https://github.com/kodal035/nodejs-app/raw/main/scripts/get_kube_token.sh
chmod +x /usr/local/bin/get_kube_token.sh
/usr/local/bin/get_kube_token.sh
