#!/bin/bash
while ! minikube status | grep -q 'host: Running'; do sleep 5; done
mkdir -p /var/lib/jenkins/.kube
cp ~/.kube/config /var/lib/jenkins/.kube/config
sudo chown jenkins:jenkins /var/lib/jenkins/.kube/config
sudo chmod 600 /var/lib/jenkins/.kube/config
