if [[ -z "$1" ]]; then
    echo "Must provide a stack name" 1>&2
    echo " eg. $0 <stack_name>" 1>&2
    exit 1
fi

SECRETS_BUCKET_NAME=$(aws --profile personal cloudformation describe-stacks --stack-name ${1} --region us-east-1 --query 'Stacks[].Outputs[?OutputKey==`SecretsStoreBucket`].OutputValue' --output text)
echo "Deleting ${SECRETS_BUCKET_NAME} bucket"

aws --profile personal s3 rb s3://${SECRETS_BUCKET_NAME} --force
