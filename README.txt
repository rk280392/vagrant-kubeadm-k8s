Deploy cilium at the end afterr joining all nodes

helm install cilium cilium/cilium --version 1.12.5 --namespace kube-system --set k8sServiceHost=$LB --set k8sServicePort=6443

