resource "yandex_kubernetes_cluster" "momo" {
  name       = "momo"
  network_id = yandex_vpc_network.momo.id

  master {
    public_ip = true

    zonal {
      zone      = var.zone
      subnet_id = yandex_vpc_subnet.momo.id
    }
  }

  service_account_id      = yandex_iam_service_account.k8s.id
  node_service_account_id = yandex_iam_service_account.k8s.id
  release_channel         = "REGULAR"

  depends_on = [yandex_resourcemanager_folder_iam_member.k8s]
}

resource "yandex_kubernetes_node_group" "workers" {
  cluster_id = yandex_kubernetes_cluster.momo.id
  name       = "workers"

  instance_template {
    platform_id = "standard-v3"

    resources {
      cores         = var.node_cores
      memory        = var.node_memory
      core_fraction = 50
    }

    boot_disk {
      type = "network-hdd"
      size = 64
    }

    scheduling_policy {
      preemptible = var.node_preemptible
    }

    # публичный IP на нодах вместо платного NAT-шлюза
    network_interface {
      subnet_ids = [yandex_vpc_subnet.momo.id]
      nat        = true
    }
  }

  scale_policy {
    fixed_scale {
      size = var.node_count
    }
  }

  allocation_policy {
    location {
      zone = var.zone
    }
  }

  maintenance_policy {
    auto_upgrade = true
    auto_repair  = true
  }
}
