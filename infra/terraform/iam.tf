# Один сервисный аккаунт для мастера и нод кластера
resource "yandex_iam_service_account" "k8s" {
  name = "momo-k8s"
}

locals {
  k8s_roles = [
    "k8s.clusters.agent",
    "vpc.publicAdmin",
    "load-balancer.admin",
    "container-registry.images.puller",
  ]
}

resource "yandex_resourcemanager_folder_iam_member" "k8s" {
  for_each  = toset(local.k8s_roles)
  folder_id = var.folder_id
  role      = each.value
  member    = "serviceAccount:${yandex_iam_service_account.k8s.id}"
}

# Сервисный аккаунт для бакета со статикой
resource "yandex_iam_service_account" "storage" {
  name = "momo-storage"
}

resource "yandex_resourcemanager_folder_iam_member" "storage" {
  folder_id = var.folder_id
  role      = "storage.editor"
  member    = "serviceAccount:${yandex_iam_service_account.storage.id}"
}

resource "yandex_iam_service_account_static_access_key" "storage" {
  service_account_id = yandex_iam_service_account.storage.id
}
