resource "yandex_storage_bucket" "static" {
  bucket     = var.static_bucket_name
  access_key = yandex_iam_service_account_static_access_key.storage.access_key
  secret_key = yandex_iam_service_account_static_access_key.storage.secret_key

  anonymous_access_flags {
    read = true
    list = false
  }

  depends_on = [yandex_resourcemanager_folder_iam_member.storage]
}
