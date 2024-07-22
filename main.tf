provider "null" {
  version = "~> 2.1"
}

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

resource "null_resource" "install_minikube" {
  provisioner "local-exec" {
    command = <<EOF
      curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
      sudo install minikube-linux-amd64 /usr/local/bin/minikube && rm minikube-linux-amd64
      minikube start --driver=docker
    EOF
    depends_on = [null_resource.install_docker]
  }
}

resource "null_resource" "install_jenkins" {
  provisioner "local-exec" {
    command = <<EOF
      sudo apt update
      sudo apt install -y openjdk-11-jdk
      wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
      sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary >> /etc/apt/sources.list'
      sudo apt update
      sudo apt install -y jenkins
      sudo systemctl start jenkins
      sudo usermod -aG docker jenkins
    EOF
    depends_on = [null_resource.install_minikube]
  }
}

resource "null_resource" "setup_kubernetes_config" {
  provisioner "local-exec" {
    command = <<EOF
      mkdir -p /var/lib/jenkins/.kube
      cp ~/.kube/config /var/lib/jenkins/.kube/config
      sudo chown jenkins:jenkins /var/lib/jenkins/.kube/config
      sudo chmod 600 /var/lib/jenkins/.kube/config
    EOF
    depends_on = [null_resource.install_jenkins]
  }
}

resource "null_resource" "update_kube_config" {
  provisioner "local-exec" {
    command = <<EOF
      CA_DATA=$(cat /home/ubuntu/.kube/config | grep 'certificate-authority-data:' | awk '{print $2}')
      CLIENT_CERT_DATA=$(cat /home/ubuntu/.minikube/profiles/minikube/client.crt | base64 -w 0)
      CLIENT_KEY_DATA=$(cat /home/ubuntu/.minikube/profiles/minikube/client.key | base64 -w 0)
      
      sed -i "s/\"certificate-authority\": \".*\"/\"certificate-authority-data\": \"${CA_DATA}\"/" /var/lib/jenkins/.kube/config
      sed -i "s/\"client-certificate\": \".*\"/\"client-certificate-data\": \"${CLIENT_CERT_DATA}\"/" /var/lib/jenkins/.kube/config
      sed -i "s/\"client-key\": \".*\"/\"client-key-data\": \"${CLIENT_KEY_DATA}\"/" /var/lib/jenkins/.kube/config
    EOF
    depends_on = [null_resource.setup_kubernetes_config]
  }
}

resource "null_resource" "create_kubernetes_resources" {
  provisioner "local-exec" {
    command = <<EOF
      kubectl create ns jenkins
      kubectl create sa jenkins -n jenkins
      kubectl create token jenkins -n jenkins --duration=8760h > /home/ubuntu/jenkins-token.txt
      kubectl create rolebinding jenkins-admin-binding --clusterrole=admin --serviceaccount=jenkins:jenkins --namespace=jenkins
    EOF
    depends_on = [null_resource.update_kube_config]
  }
}

resource "local_file" "jenkins_token" {
  depends_on = [null_resource.create_kubernetes_resources]
  content  = file("/home/ubuntu/jenkins-token.txt")
  filename = "${path.module}/jenkins-token.txt"
}

resource "null_resource" "create_pipeline" {
  provisioner "local-exec" {
    command = <<EOF
      # Install Jenkins CLI if not already installed
      if ! command -v jenkins-cli > /dev/null; then
        wget http://localhost:8080/jnlpJars/jenkins-cli.jar
      fi

      # Create Jenkins Pipeline Job
      java -jar jenkins-cli.jar -s http://localhost:8080 create-job nodejs-app < pipeline_config.xml
    EOF
    depends_on = [null_resource.install_jenkins, null_resource.create_kubernetes_resources]
  }
}

output "jenkins_url" {
  value = "http://localhost:8080"
}

output "minikube_ip" {
  value = "minikube ip"
}

output "jenkins_token" {
  value = local_file.jenkins_token.content
}
