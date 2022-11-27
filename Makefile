
deploy:
	ansible-playbook -vv deploy.yaml -i inventory.yaml

vms:
	ansible-playbook -vv deploy.yaml -i inventory.yaml -l vms
