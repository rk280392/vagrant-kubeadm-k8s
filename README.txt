
Generate cluster join for controlplane

kubeadm init phase upload-certs --upload-certs
kubeadm token create --certificate-key $certificate-key --print-join-command

Example

kubeadm join 192.168.1.2:6443 --token vqttfy.SKFPEJFzs         --discovery-token-ca-cert-hash sha256:dkvgvbikerhopqWAKJDPWEFJPV	--control-plane --certificate-key snfwdnqojgdiqusbkgckcbkdvb --apiserver-advertise-address=$IP_OF_SECOND_MASTER

Generate cluster join for worker nodes

kubeadm token create --print-join-command

Deploy cilium at the end afterr joining all nodes

helm install cilium cilium/cilium --version 1.12.5 --namespace kube-system --set k8sServiceHost=$LB --set k8sServicePort=6443 


Enable systemd for containerd else it gives error

sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
