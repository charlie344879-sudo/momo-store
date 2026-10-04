provider "yandex" {
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.zone
  # токен берётся из переменной окружения YC_TOKEN
}
