create_cluster:
	eksctl create cluster -f cluster.yaml

delete_cluster:
	eksctl delete cluster -f cluster.yaml

describe_cluster:
	eksctl utils describe-stacks --region=us-east-2 --cluster=robin-personal-cluster

aws_identity:
	aws sts get-caller-identity

set_context:
	eksctl utils write-kubeconfig --cluster=robin-personal-cluster --set-kubeconfig-context=true

enable_iam_sa_provider:
	eksctl utils associate-iam-oidc-provider --cluster=robin-personal-cluster --approve

create_cluster_role:
	kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/aws-alb-ingress-controller/v1.1.4/docs/examples/rbac-role.yaml

create_iam_policy:
	curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.2.0/docs/install/iam_policy.json
	aws iam create-policy \
		--policy-name AWSLoadBalancerControllerIAMPolicy \
		--policy-document file://iam_policy.json

create_service_account:
	eksctl create iamserviceaccount \
      --cluster=robin-personal-cluster \
      --namespace=kube-system \
      --name=aws-load-balancer-controller \
      --attach-policy-arn=arn:aws:iam::617960797257:policy/AWSLoadBalancerControllerIAMPolicy \
      --override-existing-serviceaccounts \
      --approve

deploy_cert_manager:
	kubectl apply \
		--validate=false \
		-f https://github.com/jetstack/cert-manager/releases/download/v1.1.1/cert-manager.yaml

deploy_ingress_controller:
	kubectl apply -f v2_2_0_full.yaml

deploy_application:
	kustomize build ./k8s | kubectl apply -f -

delete_application:
	kustomize build ./k8s | kubectl delete -f -

####  Argocd Commands Below ######

argo_install:
	kubectl create namespace argocd
	kubectl apply -n argocd -f k8s/argocd/argocd-install.yaml

argo_port_fwd:
	kubectl port-forward svc/argocd-server -n argocd 8080:443

argo_get_pwd:
	kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo

argo_create_project:
	kubectl apply -f argo_project.yaml

argo_create_foo_application:
	kubectl apply -f argo_foo_application.yaml

just_do_it:
	make create_cluster
	make argo_install
	make argo_create_project
	make argo_create_foo_application


replace_server_url:
	SERVER_URL="$$(yq r local_kube_config.yaml clusters.[0].cluster.server)"; \
	yq w -i argo_foo_application.yaml 'spec.destination.server' $$SERVER_URL;
