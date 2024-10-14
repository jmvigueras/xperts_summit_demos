#!/bin/bash
# -------------------------------------------------------------------------------------------------------------
# User-data script to configure a K8S node master and populate parameters
#
# jvigueras@fortinet.com
# -------------------------------------------------------------------------------------------------------------

# Variables
K8S_VERSION="v${k8s_version}"
LINUX_USER="${linux_user}"
CERT_EXTRA_SANS="${cert_extra_sans}"
DB_PASS="${db_pass}"
K8S_SA_NAME="cicd-access"

#--------------------------------------------------------------------------------------------------------------
# Install K8S (master node)
#--------------------------------------------------------------------------------------------------------------
# Install Kubernetes
mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/$K8S_VERSION/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/$K8S_VERSION/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
apt update -y
apt install -y kubeadm kubelet kubectl

apt install -y watch ipset tcpdump
          
cat <<EOF | tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

# Setup required sysctl params, these persist across reboots.
cat <<EOF | tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

# Apply sysctl params without reboot
sysctl --system

# Install containerd
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y
apt-get install -y containerd.io

# Configure containerd
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

# Restart containerd
systemctl restart containerd
swapoff -a
kubeadm config images pull

# Initialize the Kubernetes cluster
kubeadm init \
    --pod-network-cidr=192.168.0.0/16 \
    --apiserver-cert-extra-sans=127.0.0.1,$CERT_EXTRA_SANS
   #--skip-phases=addon/kube-proxy

# Export KUBECONFIG for linux_user
mkdir -p /home/$LINUX_USER/.kube
cp -i /etc/kubernetes/admin.conf /home/$LINUX_USER/.kube/config
chown $LINUX_USER /home/$LINUX_USER/.kube/config

# Export KUBECONFIG for root user
export KUBECONFIG="/etc/kubernetes/admin.conf"

# Install Calico
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.24.5/manifests/tigera-operator.yaml
curl https://raw.githubusercontent.com/projectcalico/calico/v3.24.5/manifests/custom-resources.yaml -O
sed -i 's/encapsulation: VXLANCrossSubnet/encapsulation: VXLAN/g' custom-resources.yaml
kubectl apply -f ./custom-resources.yaml

#--------------------------------------------------------------------------------------------------------------
# Create a service account and secret with a permanent cluster token
#--------------------------------------------------------------------------------------------------------------
kubectl create sa $K8S_SA_NAME -n default

# Create non expiring SA token
cat << EOF > new-sa.yaml
apiVersion: v1
kind: Secret
type: kubernetes.io/service-account-token
metadata:
  name: $K8S_SA_NAME
  annotations:
    kubernetes.io/service-account.name: $K8S_SA_NAME
EOF
kubectl apply -f new-sa.yaml

# Create a ClusterRoleBinding for the service account
kubectl create clusterrolebinding $K8S_SA_NAME --clusterrole cluster-admin --serviceaccount default:$K8S_SA_NAME

#--------------------------------------------------------------------------------------------------------------
# Disable Ubuntu OCI iptables default
#--------------------------------------------------------------------------------------------------------------
iptables -F
netfilter-persistent save

#--------------------------------------------------------------------------------------------------------------
# Remove taints in master node
#--------------------------------------------------------------------------------------------------------------
kubectl taint node --all node-role.kubernetes.io/master-
kubectl taint node --all node-role.kubernetes.io/control-plane-

#--------------------------------------------------------------------------------------------------------------
# Python script to export bootstrap token and created cicd service account to Redis
#--------------------------------------------------------------------------------------------------------------
# Install Redis and python dependencies
apt-get install -y python3-pip
apt-get install -y redis 
pip3 install redis kubernetes

# Redis DB: allow access from anywhere and set password
sed -i 's/^bind 127.0.0.1/bind 0.0.0.0/' /etc/redis/redis.conf
sh -c "echo 'requirepass $DB_PASS' >> /etc/redis/redis.conf"
systemctl restart redis-server

# Export the token and server certificate script
cat << EOF > export-cluster-info.py
${script}
EOF

# Run script
python3 export-cluster-info.py

#--------------------------------------------------------------------------------------------------------------
# Set TimeZone
#--------------------------------------------------------------------------------------------------------------
timedatectl set-timezone Europe/Madrid

#--------------------------------------------------------------------------------------------------------------
# Install Lacework agent
#--------------------------------------------------------------------------------------------------------------
cat << EOF > lacework-k8s.yaml
${lacework_k8s}
EOF
kubectl apply -f ./lacework-k8s.yaml

#--------------------------------------------------------------------------------------------------------------
# Install FortiCNP agent
#--------------------------------------------------------------------------------------------------------------
#wget https://forticwp-kubernetes-agent.s3.amazonaws.com/linux/fcli -O /tmp/fcli
#chmod +x /tmp/fcli
#/tmp/fcli deploy kubernetes --token $FORTICNP_TOKEN --region eu