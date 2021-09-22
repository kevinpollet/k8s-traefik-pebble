.PHONY: start
start: stop
	k3d cluster create test --agents 2 --image rancher/k3s:v1.21.4-k3s1 --k3s-server-arg '--no-deploy=traefik' -p "80:80@loadbalancer" -p "443:443@loadbalancer" -p "8080:8080@loadbalancer"
	kubectl apply -f coredns/
	kubectl rollout restart -n kube-system deployment/coredns
	kubectl apply -f pebble -f traefik -f whoami

.PHONY: stop
stop:
	k3d cluster delete test
