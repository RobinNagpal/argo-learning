# Step 1 - Cluster Setup
1) Create EKS Cluster using make command - `make create_cluster`

# Argo CD installation
1) Copy the cluster(server) url from `local_kube_config.yaml` and update the destination in 
   argo_foo_application.yaml
2) Install Argo CD using make command `make argo_install`
3) Do port forwarding on Argo CD to be able to login from local `make argo_port_fwd`
4) Grab the Argo CD password using `make argo_get_pwd`
5) Login to Argo CD UI


# Create Project
1) make `argo_create_project`

# Deploy Foo application
