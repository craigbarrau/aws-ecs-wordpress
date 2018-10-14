echo "Default to us-east-1 region"

if [[ -z "$1" ]]; then
    echo "Must provide a stack name" 1>&2
    echo " eg. $0 <stack_name>" 1>&2
    exit 1
fi

while aws --profile personal cloudformation describe-stacks --region us-east-1 --stack-name ${1} --query "Stacks[*].StackStatus" --output text | grep -q CREATE_IN_PROGRESS; do echo "Waiting for stack"; sleep 10; done
CLOUDFORMATION_STATUS=$(aws --profile personal cloudformation describe-stacks --region us-east-1 --stack-name ${1} --query "Stacks[*].StackStatus" --output text) || { exit 1; }
if [ $CLOUDFORMATION_STATUS = "CREATE_COMPLETE" ]; then
   echo "The stack was created successfully"
else
  echo "$CLOUDFORMATION_STATUS"
  echo "Error creating the stack. Will rollback"
  exit 1
fi
