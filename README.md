1) Launch Vault instance locally, and export VAULT_ADDR and VAULT_TOKEN to env
2) Launch minikube locally `minikube start`
3) Expose the api server `kubectl proxy --port=9090`, it should return something like `Starting to serve on 127.0.0.1:9090`.
4) Verify that `127.0.0.1/openid/v1/jwks` is reachable
5) Update the `var` `kubect_ip` in `main.tf` it the output from `kubectl proxy --port=9090` has a different IP
6) terraform init and apply
