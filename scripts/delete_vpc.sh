VPC_ID=$(cat state/vpc-endpoint.json | jq -r .VpcEndpoint.VpcEndpointId)
echo "Deleting VPC Endpoint ${VPC_ID}"

aws ec2 --profile personal --region us-east-1 delete-vpc --vpc-id ${VPC_ID}
