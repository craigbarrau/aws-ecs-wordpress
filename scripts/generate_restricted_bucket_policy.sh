if [[ -z "$1" ]]; then
    echo "Must provide a stack name" 1>&2
    echo " eg. $0 <stack_name>" 1>&2
    exit 1
fi

echo "Creating S3 VPC endpoint"
aws --profile personal ec2 create-vpc-endpoint \
  --vpc-id $(aws --profile personal cloudformation describe-stacks --stack-name ${1} --region us-east-1 --query 'Stacks[].Outputs[?OutputKey==`VPC`].OutputValue' --output text) \
  --route-table-ids $(aws --profile personal cloudformation describe-stacks --stack-name ${1} --region us-east-1 --query 'Stacks[].Outputs[?OutputKey==`RouteTable`].OutputValue' --output text) \
  --service-name com.amazonaws.us-east-1.s3 --region us-east-1 > state/vpc-endpoint.json

SECRETS_VPC_ENDPOINT=$(cat state/vpc-endpoint.json | jq -r .VpcEndpoint.VpcEndpointId)
echo "Created VPC endpoint ${SECRETS_VPC_ENDPOINT}"

SECRETS_BUCKET_NAME=$(aws --profile personal cloudformation describe-stacks --stack-name ${1} --region us-east-1 --query 'Stacks[].Outputs[?OutputKey==`SecretsStoreBucket`].OutputValue' --output text)
echo "Updating bucket policy for ${SECRETS_BUCKET_NAME}"

BUCKET_POLICY=$(cat <<ENDOFTEMPLATE
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyUnEncryptedObjectUploads",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::${SECRETS_BUCKET_NAME}/*",
      "Condition": {
        "StringNotEquals": {
          "s3:x-amz-server-side-encryption": "AES256"
        }
      }
    },
    {
      "Sid": " DenyUnEncryptedInflightOperations",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": "arn:aws:s3:::${SECRETS_BUCKET_NAME}/*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": false
        }
      }
    },
    {
      "Sid": "Access-to-specific-VPCE-only",
      "Effect": "Deny",
      "Principal": "*",
      "Action": [ "s3:GetObject", "s3:PutObject", "s3:DeleteObject" ],
      "Resource": "arn:aws:s3:::${SECRETS_BUCKET_NAME}/*",
      "Condition": {
        "StringNotEquals": {
          "aws:sourceVpce": "${SECRETS_VPC_ENDPOINT}"
        }
      }
    }
  ]
}
ENDOFTEMPLATE
)

aws --profile personal s3api put-bucket-policy --bucket ${SECRETS_BUCKET_NAME} --policy "${BUCKET_POLICY}"
