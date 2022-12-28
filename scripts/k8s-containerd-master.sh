#!/bin/bash

set -e

export WGET='wget -q --show-progress --https-only'
NODENAME=$(hostname -s)
LB_IP=192.168.1.2

for i in $(cat /vagrant/file.txt | awk '{print $2}'); do
  MASTER_IP="$i"
done

sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl
sudo curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

echo "memory swapoff"
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
sudo swapoff -a

$WGET https://github.com/containerd/containerd/releases/download/v1.6.14/containerd-1.6.14-linux-amd64.tar.gz
tar Cxzvf /usr/local containerd-1.6.14-linux-amd64.tar.gz

$WGET https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
mv containerd.service /etc/systemd/system/
sudo mkdir -p /etc/containerd/
sudo containerd config default > /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml


$WGET https://github.com/opencontainers/runc/releases/download/v1.1.4/runc.amd64
install -m 755 runc.amd64 /usr/local/sbin/runc


sudo modprobe overlay
sudo modprobe br_netfilter
sudo tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sudo tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF

sysctl --system

sudo apt install jq -y

local_ip="$(ip --json a s | jq -r '.[] | if .ifname == "eth1" then .addr_info[] | if .family == "inet" then .local else empty end else empty end')"
cat > /etc/default/kubelet << EOF
KUBELET_EXTRA_ARGS=--node-ip=$local_ip
EOF

sudo systemctl restart containerd
sudo systemctl enable containerd   

sudo systemctl enable kubelet
sudo systemctl restart kubelet

config_path="/vagrant/configs"
if [ -d $config_path ]; then
  rm -f $config_path/*
else
  mkdir -p $config_path
fi

sudo kubeadm init   --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=$MASTER_IP --apiserver-cert-extra-sans=$MASTER_IP  --upload-certs  --control-plane-endpoint=$LB_IP  --cri-socket unix:///var/run/containerd/containerd.sock --node-name="$NODENAME" &> $config_path/join-commands.txt
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
export KUBECONFIG=/etc/kubernetes/admin.conf

wget https://get.helm.sh/helm-v3.7.2-linux-amd64.tar.gz
tar -xvf helm-v3.7.2-linux-amd64.tar.gz
mv linux-amd64/helm /usr/local/bin/

sudo cp -i /etc/kubernetes/admin.conf $config_path/config
sudo touch $config_path/join.sh
sudo chmod +x $config_path/join.sh

sudo kubeadm token create --print-join-command > $config_path/join.sh

# Install Metrics Server

#kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

helm repo add cilium https://helm.cilium.io/
#helm install cilium cilium/cilium --version 1.12.5 --namespace kube-system --set k8sServiceHost=$LB --set k8sServicePort=6443
