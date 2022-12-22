
.PHONY: deploy
deploy:
	ansible-playbook -vv deploy.yaml -i inventory.yaml

.PHONY: kustomize
kustomize:
	ansible-playbook -vv deploy.yaml -i inventory.yaml -t kustomize

.PHONY: host
host:
	ansible-playbook -vv deploy.yaml -i inventory.yaml -t host
