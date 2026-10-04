#!/usr/bin/env bash
# Готовит чистую Ubuntu 24.04 как рабочую станцию для проекта momo-store:
# docker, kubectl, kind, helm, terraform (через зеркало Яндекса), yc CLI.
# Запуск: bash setup-dev-vm.sh   (от обычного пользователя с sudo)
set -euo pipefail

TF_VERSION="${TF_VERSION:-1.9.8}"
KIND_VERSION="${KIND_VERSION:-v0.24.0}"
ARCH=amd64

sudo apt-get update
sudo apt-get install -y docker.io curl unzip git jq ca-certificates
sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"

# kubectl
curl -fsSLo /tmp/kubectl "https://dl.k8s.io/release/$(curl -fsSL https://dl.k8s.io/release/stable.txt)/bin/linux/${ARCH}/kubectl"
sudo install -m 0755 /tmp/kubectl /usr/local/bin/kubectl

# kind
curl -fsSLo /tmp/kind "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-${ARCH}"
sudo install -m 0755 /tmp/kind /usr/local/bin/kind

# helm
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# terraform: бинарник и провайдеры с зеркал Яндекса
curl -fsSLo /tmp/terraform.zip "https://hashicorp-releases.yandexcloud.net/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_${ARCH}.zip"
sudo unzip -o /tmp/terraform.zip terraform -d /usr/local/bin
cat > "$HOME/.terraformrc" <<'RC'
provider_installation {
  network_mirror {
    url     = "https://terraform-mirror.yandexcloud.net/"
    include = ["registry.terraform.io/*/*"]
  }
  direct {
    exclude = ["registry.terraform.io/*/*"]
  }
}
RC

# yc CLI
curl -fsSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash -s -- -a

echo
echo "Готово. Перелогинься (чтобы заработала группа docker), затем:"
echo "  kind create cluster --config infra/local/kind-config.yaml"
echo "  terraform -version && helm version && kubectl version --client"
