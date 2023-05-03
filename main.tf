# steps before running it
# 
terraform {
  required_providers {
    vault = {
      version = "3.15.0"
    }

    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.20.0"
    }
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "minikube"
}

provider "vault" {
}

/*
We're generating 4 service accounts in kubernetes, each one is name terraform-sa-1, terraform-sa-2, ... 
*/
resource "kubernetes_service_account" "example" {
    count = 4
    metadata {
        name = "terraform-sa-${count.index}"
    }
}

/**
output "name" {
  value = [for item in kubernetes_service_account.example: item.metadata[0].name]
}*/


variable "kube_ip" {
  default = "127.0.0.1:9090"
}

/*
Basic setup of the auth method
*/
resource "vault_jwt_auth_backend" "jwt" {
    path = "jwt"
    jwks_url = "http://${var.kube_ip}/openid/v1/jwks"
}


/*
We're looping through all the service accounts previously and are creating a individual role named role-terraform-sa-1, role-terraform-sa-2, ... 
Each one of these roles has for now the default policy attached, you can create a custom policy
To authenticate you can go to your terminal and execute 
kubectl create token terraform-sa-1 
this will return a token. 
Now go to your vault login screen and choose the jwt auth method, type in the role `role-terraform-sa-1` and paste the token
You're logged in

Do this for all the service accounts and take a look at the entities, there is just one entity named `default` for all your roles. 
so juse one client

*/
resource "vault_jwt_auth_backend_role" "example" {
    count = length(kubernetes_service_account.example)    
    
  backend         = vault_jwt_auth_backend.jwt.path
  role_name       = "role-${tolist(kubernetes_service_account.example)[count.index].metadata[0].name}"
  role_type       = "jwt"
  token_policies  = ["default"] // TODO create custom policy for each one
  user_claim      = "/kubernetes.io/namespace"
  user_claim_json_pointer = true
  bound_audiences = ["https://kubernetes.default.svc.cluster.local"]
  bound_claims = {
    "/kubernetes.io/serviceaccount/name": tolist(kubernetes_service_account.example)[count.index].metadata[0].name
  }
}
