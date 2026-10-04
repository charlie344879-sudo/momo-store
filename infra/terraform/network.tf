resource "yandex_vpc_network" "momo" {
  name = "momo-network"
}

resource "yandex_vpc_subnet" "momo" {
  name           = "momo-subnet-${var.zone}"
  zone           = var.zone
  network_id     = yandex_vpc_network.momo.id
  v4_cidr_blocks = ["10.10.0.0/24"]
}
