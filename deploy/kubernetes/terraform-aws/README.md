# Running AWS Kubernetes Cluster with Terraform

This directory provides code to install Kubernetes 1.6 Cluster to AWS with Terraform deployment scripts

## Prerequisites
- Terraform
for MacOS:
```
brew install terraform
```

## Quick start

```
export TF_VAR_aws_key_name=<AWS-SSH-KEY-NAME> ; export TF_VAR_private_key_file=path/to/ssh/pem ; export TF_VAR_access_key=<AWS-ACCESS-KEY> ; export TF_VAR_secret_key=<AWS-SECRET-KEY> 
terraform apply
```

## Check list of nodes
ssh -i <key> ubuntu@master-node
kubectl get nodes
kubectl get pods
kubectl get svcs

## Install WeaveScope

```
kubectl apply -f https://cloud.weave.works/k8s.yaml?t=<your-weavecloud-token>
```

Weave Scope URL: https://cloud.weave.works/app/<your-app-name>

## Sock-Shop demo app

Run:
```
ssh -i <key> ubuntu@master-node
kubectl apply -n sock-shop -f "https://github.com/microservices-demo/microservices-demo/blob/master/deploy/kubernetes/complete-demo.yaml?raw=true"
```

Destroy:
```
ssh -i <key> ubuntu@master-node
kubectl delete -n sock-shop -f "https://github.com/microservices-demo/microservices-demo/blob/master/deploy/kubernetes/complete-demo.yaml?raw=true"
```

## Destroy cluster
terraform destroy

## Debugging

To ssh into the instance, export the variables returned by terraform, then: `ssh -i $KEY ubuntu@$IP`
