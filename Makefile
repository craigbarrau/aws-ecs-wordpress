include environment

run: build-image create-stack push-image run-wordpress

build-image:
	docker build $(AWS_ECR_NAME)/secure-wordpress docker

push-image:
	docker push $(AWS_ECR_NAME)/secure-wordpress

create-cf:
	@aws --profile personal cloudformation create-stack --region us-east-1 \
	--stack-name $(AWS_STACK_NAME) \
	--capabilities CAPABILITY_IAM \
	--template-body file://templates/cloudformation.json \
	--parameters ParameterKey=DbPassword,ParameterValue=$(AWS_RDS_PASSWORD) \
	ParameterKey=InstanceType,ParameterValue=$(AWS_INSTANCE_TYPE) \
	ParameterKey=KeyName,ParameterValue=$(AWS_KEY_NAME) \
	ParameterKey=SourceCidr,ParameterValue=$(AWS_SOURCE_CIDR)
	@./scripts/wait_for_cf.sh $(AWS_STACK_NAME)
	@./scripts/generate_encrypted_bucket_policy.sh $(AWS_STACK_NAME)

create-stack: create-cf
	@./scripts/write_password_to_bucket.sh $(AWS_STACK_NAME) $(AWS_RDS_PASSWORD)
  #Commented as I couldn't get it to work. See 'Known Issues' in README.md
	#@./scripts/generate_restricted_bucket_policy.sh $(AWS_STACK_NAME)

run-wordpress:
	@./scripts/create_ecs.sh $(AWS_STACK_NAME)

destroy: delete-ecs destroy-image destroy-stack

destroy-ecs:
	@./scripts/delete_ecs.sh $(AWS_STACK_NAME)

destroy-image:
	@./scripts/delete_images.sh

destroy-stack:
	@./scripts/delete_stack.sh $(AWS_STACK_NAME)
