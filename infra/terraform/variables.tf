variable "cloud_id" {
  type = string
}

variable "folder_id" {
  type = string
}

variable "zone" {
  type    = string
  default = "ru-central1-a"
}

variable "static_bucket_name" {
  type        = string
  description = "Глобально уникальное имя бакета для статики"
}

variable "node_count" {
  type    = number
  default = 2
}

variable "node_cores" {
  type    = number
  default = 2
}

variable "node_memory" {
  type    = number
  default = 4
}

variable "node_preemptible" {
  type        = bool
  default     = true
  description = "Прерываемые ноды дешевле, но нужен node-termination-handler"
}
