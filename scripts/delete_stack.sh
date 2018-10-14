if [[ -z "$1" ]]; then
    echo "Must provide a stack name" 1>&2
    echo " eg. $0 <stack_name>" 1>&2
    exit 1
fi

aws --profile personal --region us-east-1 cloudformation delete-stack --stack-name ${1}
while aws --profile personal --region us-east-1 cloudformation describe-stacks --stack-name ${1} --query "Stacks[*].StackStatus" --output text | grep -q DELETE_IN_PROGRESS; do sleep 30; echo "Deleting the stack"; done
