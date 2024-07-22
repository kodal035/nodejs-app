#!/bin/bash

# Token'i al
TOKEN=$(kubectl create token jenkins -n jenkins --duration=8760h)

# Token'i dosyaya yaz
echo $TOKEN > /usr/local/bin/kube_token.txt
