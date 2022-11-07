#!/bin/bash
#Kubernetes control pane initialization script for Ubuntu 20.04

#Upgrade the system
sudo apt-get update && apt-get upgrade -y
sudo apt install curl apt-transport-https vim git wget gnupg2 software-properties-common apt-transport-https ca-certificates uidmap -y

#Disable swap
sudo swapoff -a

#Load modules to ensure they are available for following steps
sudo modprobe overlay
sudo modprobe br_netfilter

#Update kernel networking to allow necessary traffic
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

#Ensure the changes are used by the current kernel as well
sudo sysctl --system

#Install the necessary key for the software to install
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

#Install the containerd software.
sudo apt install containerd -y

#Add a new repo for kubernetes and add a GPG key for the packages.
sudo sh -c "echo 'deb http://apt.kubernetes.io/ kubernetes-xenial main' >> /etc/apt/sources.list.d/kubernetes.list"
sudo sh -c "curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -"

#Download updated repo information
sudo apt-get update

#Install the Kubernetes software
sudo apt-get install -y kubeadm=1.24.1-00 kubelet=1.24.1-00 kubectl=1.24.1-00

#Hold the software at the recent but stable version we install
sudo apt-mark hold kubelet kubeadm kubectl

#Add an local DNS alias for our cp server.
sudo -- sh -c "echo $(hostname -I) k8scp >> /etc/hosts"

#Download configuration file for the cluster
wget -O kubeadm-config.yaml https://raw.githubusercontent.com/pbuszczyk/k8s/main/kubeadm-config.yaml

#Initialize the cp and save output for future review
sudo kubeadm init --config=kubeadm-config.yaml --upload-certs | tee kubeadm-init.out

#Allow current user admin level access to the cluster
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

#Download and apply the network plugin configuration for your cluster
wget https://docs.projectcalico.org/manifests/calico.yaml
kubectl apply -f calico.yaml

#Enable bash auto-completion for kubectl
sudo apt-get install bash-completion -y
source <(kubectl completion bash)
echo "source <(kubectl completion bash)" >> $HOME/.bashrc
source ~/.bashrc
