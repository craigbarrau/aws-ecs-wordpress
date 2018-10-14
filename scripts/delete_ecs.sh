if [[ -z "$1" ]]; then
    echo "Must provide a stack name" 1>&2
    echo " eg. $0 <stack_name>" 1>&2
    exit 1
fi

#--service wordpress

aws ecs --profile personal --region us-east-1 update-service \
--cluster $(aws --profile personal cloudformation describe-stacks --stack-name ${1} --region us-east-1 --query 'Stacks[].Outputs[?OutputKey==`EcsCluster`].OutputValue' --output text) \
--service wordpress --desired-count 0

aws --profile personal --region us-east-1 ecs delete-service \
--cluster $(aws --profile personal cloudformation describe-stacks --stack-name ${1} --region us-east-1 --query 'Stacks[].Outputs[?OutputKey==`EcsCluster`].OutputValue' --output text) \
--service wordpress
