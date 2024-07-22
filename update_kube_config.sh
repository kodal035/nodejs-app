#!/bin/bash

# Kube konfigürasyon dosyasının yolu
KUBECONFIG_FILE="/var/lib/jenkins/.kube/config"

# Konfigürasyon dosyasının mevcut ayarlarını alın
CA_DATA=$(grep 'certificate-authority-data:' ~/.kube/config | awk '{print $2}')
CLIENT_CERT_DATA=$(base64 -w 0 ~/.minikube/profiles/minikube/client.crt)
CLIENT_KEY_DATA=$(base64 -w 0 ~/.minikube/profiles/minikube/client.key)

# Konfigürasyonu güncelle
sudo su -c "sed -i 's/\"certificate-authority\": \".*\"/\"certificate-authority-data\": \"${CA_DATA}\"/' $KUBECONFIG_FILE"
sudo su -c "sed -i 's/\"client-certificate\": \".*\"/\"client-certificate-data\": \"${CLIENT_CERT_DATA}\"/' $KUBECONFIG_FILE"
sudo su -c "sed -i 's/\"client-key\": \".*\"/\"client-key-data\": \"${CLIENT_KEY_DATA}\"/' $KUBECONFIG_FILE"
