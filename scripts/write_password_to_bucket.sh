if [[ -z "$1" ]]; then
    echo "Must provide a stack" 1>&2
    echo " eg. $0 <stack_name> <password>" 1>&2
    exit 1
fi
if [[ -z "$2" ]]; then
    echo "Must provide a password" 1>&2
    echo " eg. $0 <stack_name> <password>" 1>&2
    exit 1
fi

SECRETS_BUCKET_NAME=$(aws --profile personal cloudformation describe-stacks --stack-name ${1} --region us-east-1 --query 'Stacks[].Outputs[?OutputKey==`SecretsStoreBucket`].OutputValue' --output text)
echo "Uploading credentials to ${SECRETS_BUCKET_NAME}"

# Note: user provided file can't be from /tmp
#       seems to be an AWS client constraint
echo "WORDPRESS_DB_PASSWORD=${2}" > db_credentials.txt
aws --profile personal \
  s3 cp db_credentials.txt \
  s3://${SECRETS_BUCKET_NAME}/db_credentials.txt --sse
rm db_credentials.txt
