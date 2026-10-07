# Одноразовый bootstrap: бакет для state основного Terraform и сервисный аккаунт к нему.
# State самого bootstrap хранится локально (не коммитится).
terraform {
  required_version = ">= 1.5"
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.130"
    }
  }
}

variable "cloud_id" { type = string }
variable "folder_id" { type = string }
variable "state_bucket_name" {
  type        = string
  description = "Глобально уникальное имя бакета для tfstate"
}

provider "yandex" {
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = "ru-central1-a"
  # токен берётся из переменной окружения YC_TOKEN
}

resource "yandex_iam_service_account" "tfstate" {
  name = "momo-tfstate"
}

resource "yandex_resourcemanager_folder_iam_member" "tfstate_storage" {
  folder_id = var.folder_id
  role      = "storage.admin"
  member    = "serviceAccount:${yandex_iam_service_account.tfstate.id}"
}

resource "yandex_iam_service_account_static_access_key" "tfstate" {
  service_account_id = yandex_iam_service_account.tfstate.id
}

resource "yandex_storage_bucket" "tfstate" {
  bucket     = var.state_bucket_name
  access_key = yandex_iam_service_account_static_access_key.tfstate.access_key
  secret_key = yandex_iam_service_account_static_access_key.tfstate.secret_key

  versioning {
    enabled = true
  }

  depends_on = [yandex_resourcemanager_folder_iam_member.tfstate_storage]
}

output "access_key" {
  value     = yandex_iam_service_account_static_access_key.tfstate.access_key
  sensitive = true
}
output "secret_key" {
  value     = yandex_iam_service_account_static_access_key.tfstate.secret_key
  sensitive = true
}
output "state_bucket" {
  value = yandex_storage_bucket.tfstate.bucket
}
