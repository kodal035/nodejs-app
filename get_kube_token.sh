data "external" "kubernetes_token" {
  program = ["bash", "${path.module}/scripts/get_kube_token.sh"]
}
