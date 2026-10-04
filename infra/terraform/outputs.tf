output "cluster_id" {
  value = yandex_kubernetes_cluster.momo.id
}

output "static_bucket" {
  value = yandex_storage_bucket.static.bucket
}

output "kubeconfig_command" {
  value = "yc managed-kubernetes cluster get-credentials ${yandex_kubernetes_cluster.momo.name} --external"
}
