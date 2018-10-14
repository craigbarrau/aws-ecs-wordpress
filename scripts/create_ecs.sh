if [[ -z "$1" ]]; then
    echo "Must provide a stack name" 1>&2
    echo " eg. $0 <stack_name>" 1>&2
    exit 1
fi

aws --profile personal ecs create-service \
--cluster $(aws --profile personal cloudformation describe-stacks --stack-name ${1} --region us-east-1 --query 'Stacks[].Outputs[?OutputKey==`EcsCluster`].OutputValue' --output text) \
--service-name wordpress \
--task-definition $(aws --profile personal cloudformation describe-stacks --stack-name ${1} --region us-east-1 --query 'Stacks[].Outputs[?OutputKey==`WordPressTaskDefinition`].OutputValue' --output text) \
--desired-count 1 --region us-east-1

echo "Access the Wordpress site at:"
echo $(aws --profile personal cloudformation describe-stacks --stack-name ${1} --region us-east-1 --query 'Stacks[].Outputs[?OutputKey==`WordPressURL`].OutputValue' --output text)
