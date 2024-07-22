resource "null_resource" "fetch_scripts" {
  provisioner "local-exec" {
    command = <<EOF
      #!/bin/bash
      echo "Fetching scripts..."
      bash /mnt/c/Users/abdul/aws/selman/terraform/fetch_scripts.sh
      echo "Scripts fetched."
    EOF
  }
}

resource "null_resource" "install_docker" {
  provisioner "local-exec" {
    command = <<EOF
      #!/bin/bash
      echo "Installing Docker..."
      bash /mnt/c/Users/abdul/aws/selman/terraform/install_docker.sh
      echo "Docker installation completed."
      sleep 60  # Wait for 1 minute
    EOF
  }

  depends_on = [null_resource.fetch_scripts]
}

resource "null_resource" "install_minikube" {
  provisioner "local-exec" {
    command = <<EOF
      #!/bin/bash
      echo "Installing Minikube..."
      bash /mnt/c/Users/abdul/aws/selman/terraform/install_minikube.sh
      echo "Minikube installation completed."
      sleep 120  # Wait for 2 minutes
    EOF
  }

  depends_on = [null_resource.install_docker]
}

resource "null_resource" "setup_kubernetes_config" {
  provisioner "local-exec" {
    command = <<EOF
      #!/bin/bash
      echo "Updating Kubernetes configuration..."
      bash /mnt/c/Users/abdul/aws/selman/terraform/setup_kubernetes_config.sh
      echo "Kubernetes configuration updated."
    EOF
  }

  depends_on = [null_resource.install_minikube]
}

resource "null_resource" "install_jenkins" {
  provisioner "local-exec" {
    command = <<EOF
      #!/bin/bash
      echo "Installing Jenkins..."
      bash /mnt/c/Users/abdul/aws/selman/terraform/install_jenkins.sh
      echo "Jenkins installation completed."
    EOF
  }

  depends_on = [null_resource.setup_kubernetes_config]
}

resource "null_resource" "update_kube_config" {
  provisioner "local-exec" {
    command = <<EOF
      #!/bin/bash
      echo "Updating Kubernetes configuration..."
      bash /mnt/c/Users/abdul/aws/selman/terraform/update_kube_config.sh
      echo "Kubernetes configuration updated."
    EOF
  }

  depends_on = [null_resource.install_jenkins]
}

resource "null_resource" "create_kubernetes_resources" {
  provisioner "local-exec" {
    command = <<EOF
      #!/bin/bash
      echo "Creating Kubernetes resources..."
      bash /mnt/c/Users/abdul/aws/selman/terraform/create_kubernetes_resources.sh
      echo "Kubernetes resources created."
    EOF
  }

  depends_on = [null_resource.update_kube_config]
}

resource "null_resource" "create_pipeline" {
  provisioner "local-exec" {
    command = <<EOF
      #!/bin/bash
      echo "Creating Jenkins pipeline..."
      bash /mnt/c/Users/abdul/aws/selman/terraform/create_pipeline.sh
      echo "Jenkins pipeline created."
    EOF
  }

  depends_on = [null_resource.create_kubernetes_resources]
}
