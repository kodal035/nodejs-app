resource "null_resource" "fetch_scripts" {
  provisioner "local-exec" {
    command = "bash /mnt/c/Users/abdul/aws/selman/terraform/fetch_scripts.sh"
  }
}

resource "null_resource" "install_docker" {
  provisioner "local-exec" {
    command = "bash /mnt/c/Users/abdul/aws/selman/terraform/install_docker.sh"
  }
}

resource "null_resource" "install_minikube" {
  provisioner "local-exec" {
    command = "bash /mnt/c/Users/abdul/aws/selman/terraform/install_minikube.sh"
  }
}

resource "null_resource" "install_jenkins" {
  provisioner "local-exec" {
    command = "bash /mnt/c/Users/abdul/aws/selman/terraform/install_jenkins.sh"
  }
}

resource "null_resource" "setup_kubernetes_config" {
  provisioner "local-exec" {
    command = "bash /mnt/c/Users/abdul/aws/selman/terraform/setup_kubernetes_config.sh"
  }
}

resource "null_resource" "update_kube_config" {
  provisioner "local-exec" {
    command = "bash /mnt/c/Users/abdul/aws/selman/terraform/update_kube_config.sh"
  }
}

resource "null_resource" "create_kubernetes_resources" {
  provisioner "local-exec" {
    command = "bash /mnt/c/Users/abdul/aws/selman/terraform/create_kubernetes_resources.sh"
  }
}

resource "null_resource" "create_pipeline" {
  provisioner "local-exec" {
    command = "bash /mnt/c/Users/abdul/aws/selman/terraform/create_pipeline.sh"
  }
}
