terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 2.1"
    }
  }
}

provider "null" {}

# Scriptleri GitHub'dan Çek
resource "null_resource" "fetch_scripts" {
  provisioner "local-exec" {
    command = <<EOF
      # GitHub'dan Scriptleri Çek
      git clone https://github.com/kodal035/nodejs-app.git /tmp/nodejs-app
      cp /tmp/nodejs-app/scripts/* /usr/local/bin/
      chmod +x /usr/local/bin/*.sh
    EOF
  }
}

# Docker Kurulumu
resource "null_resource" "install_docker" {
  provisioner "local-exec" {
    command = <<EOF
      for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove -y $pkg; done

      sudo apt-get update
      sudo apt-get install -y ca-certificates curl
      sudo install -m 0755 -d /etc/apt/keyrings
      sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
      sudo chmod a+r /etc/apt/keyrings/docker.asc

      echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
      sudo apt-get update
      sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
      sudo groupadd docker
      sudo usermod -aG docker $USER
      newgrp docker
      sudo systemctl enable docker.service
      sudo systemctl enable containerd.service
    EOF
  }
}

# Minikube Kurulumu
resource "null_resource" "install_minikube" {
  provisioner "local-exec" {
    command = <<EOF
      curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
      sudo install minikube-linux-amd64 /usr/local/bin/minikube && rm minikube-linux-amd64
      minikube start --driver=docker
    EOF
  }
}

# Jenkins Kurulumu
resource "null_resource" "install_jenkins" {
  provisioner "local-exec" {
    command = <<EOF
      # Jenkins Keyring'ini İndirin ve Kurun
      sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
        https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key

      # Jenkins Depo Kaydını Ekleyin
      echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
        https://pkg.jenkins.io/debian-stable binary/" | sudo tee \
        /etc/apt/sources.list.d/jenkins.list > /dev/null

      # Paket Listelerini Güncelleyin
      sudo apt-get update

      # Jenkins'i Kurun
      sudo apt-get install -y jenkins

      # Jenkins Servisini Başlatın ve Etkinleştirin
      sudo systemctl enable jenkins
      sudo systemctl start jenkins
    EOF
  }
}

# Kubernetes Konfigürasyonunu Ayarla
resource "null_resource" "setup_kubernetes_config" {
  provisioner "local-exec" {
    command = <<EOF
      mkdir -p /var/lib/jenkins/.kube
      cp ~/.kube/config /var/lib/jenkins/.kube/config
      sudo chown jenkins:jenkins /var/lib/jenkins/.kube/config
      sudo chmod 600 /var/lib/jenkins/.kube/config
    EOF
  }
}

# Kubernetes Konfigürasyonunu Güncelle
resource "null_resource" "update_kube_config" {
  provisioner "local-exec" {
    command = <<EOF
      # get_kube_token.sh'i GitHub'dan Çek
      curl -L -o /usr/local/bin/get_kube_token.sh https://github.com/kodal035/nodejs-app/raw/main/scripts/get_kube_token.sh
      chmod +x /usr/local/bin/get_kube_token.sh

      # Kube Token'i Al
      TOKEN=$(bash /usr/local/bin/get_kube_token.sh)
      CA_DATA=$(cat ~/.kube/config | grep 'certificate-authority-data:' | awk '{print $2}')
      CLIENT_CERT_DATA=$(cat ~/.minikube/profiles/minikube/client.crt | base64 -w 0)
      CLIENT_KEY_DATA=$(cat ~/.minikube/profiles/minikube/client.key | base64 -w 0)
      
      sudo su -c "sed -i 's/\"certificate-authority\": \".*\"/\"certificate-authority-data\": \"${CA_DATA}\"/' /var/lib/jenkins/.kube/config"
      sudo su -c "sed -i 's/\"client-certificate\": \".*\"/\"client-certificate-data\": \"${CLIENT_CERT_DATA}\"/' /var/lib/jenkins/.kube/config"
      sudo su -c "sed -i 's/\"client-key\": \".*\"/\"client-key-data\": \"${CLIENT_KEY_DATA}\"/' /var/lib/jenkins/.kube/config"
    EOF
  }
}

# Kubernetes Kaynaklarını Oluştur
resource "null_resource" "create_kubernetes_resources" {
  provisioner "local-exec" {
    command = <<EOF
      kubectl create ns jenkins
      kubectl create sa jenkins -n jenkins
      kubectl create token jenkins -n jenkins --duration=8760h
      kubectl create rolebinding jenkins-admin-binding --clusterrole=admin --serviceaccount=jenkins:jenkins --namespace=jenkins
    EOF
  }
}

# Jenkins Pipeline'ı Oluştur
resource "null_resource" "create_pipeline" {
  provisioner "local-exec" {
    command = <<EOF
      # GitHub'dan pipeline_config.xml'i çek
      curl -L -o pipeline_config.xml https://github.com/kodal035/nodejs-app/raw/main/pipeline_config.xml

      # Jenkins CLI ile pipeline oluştur
      if ! command -v jenkins-cli > /dev/null; then
        wget http://localhost:8080/jnlpJars/jenkins-cli.jar
      fi

      java -jar jenkins-cli.jar -s http://localhost:8080 create-job nodejs-app < pipeline_config.xml
    EOF
  }
}

# Kubernetes Token'ını Almak İçin External Kaynağı
data "external" "kubernetes_token" {
  program = ["bash", "${path.module}/scripts/get_kube_token.sh"]
}

# Çıktılar
output "jenkins_url" {
  value = "http://localhost:8080"
}

output "minikube_ip" {
  value = "minikube ip"
}

output "kubernetes_token" {
  value = "${chomp(data.external.kubernetes_token.result)}"
}
