
deploy args="":
	ANSIBLE_STDOUT_CALLBACK=debug ansible-playbook -vv deploy.yaml -i inventory.yaml {{args}}

kustomize:
	ansible-playbook -vv deploy.yaml -i inventory.yaml -t kustomize

host:
	ansible-playbook -vv deploy.yaml -i inventory.yaml -t host

bootstrap args="":
	ansible-playbook -vv -e \"ansible_ssh_extra_args=-o\ StrictHostKeyChecking=no\" bootstrap/bootstrap.yaml -i inventory.yaml {{args}} 
