.PHONY: help
help:  ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: start
start: stop ## Start a k3d cluster named test
	k3d cluster create test --agents 2 --image rancher/k3s:v1.21.4-k3s1 --k3s-server-arg '--no-deploy=traefik' -p "80:80@loadbalancer" -p "443:443@loadbalancer" -p "8080:8080@loadbalancer"
	kubectl apply -f coredns/
	kubectl rollout restart -n kube-system deployment/coredns
	kubectl apply -f pebble -f traefik -f whoami

.PHONY: stop
stop: ## Stop the k3d cluster named test
	k3d cluster delete test
