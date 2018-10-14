# AWS ECS+RDS+S3 Wordpress Example

The below example is inspired by [this blog post](https://aws.amazon.com/blogs/security/how-to-manage-secrets-for-amazon-ec2-container-service-based-applications-by-using-amazon-s3-and-docker/).

Through the power of CloudFormation you can easily create an AWS stack with:
- ECS cluster running wordpress in a Docker container (1 replica)
- RDS MySQL instance for wordpress
- ECR for storing the wordpress docker image
- VPC for isolation
- Encrypted S3 bucket containing the MySQL credential for connectivity from the Docker container
- ~~Access to the S3 bucket restricted to the ECS cluster VPC~~ See [Known Issues](https://github.com/craigbarrau/aws-ecs-wordpress#known-issues)

After the stack is created, you can customise the official
wordpress docker image to get the secret from the S3 bucket.
This customised docker image can be pushed to ECR so it can
be pulled down and ran from ECS.

# Prerequisites

1. Ensure you have an SSH key created in EC2
2. Ensure you have an IAM user created with access keys generated
3. Ensure you have AWS CLI installed and configured with a `personal` profile for the IAM user access keys

# Assumptions

- All of the below scripts and code snippets assume that you are using
an AWS CLI profile called `personal` and the `us-east-1` region.
- Whilst it would be possible to parameterise these, I ran out of time
to do so. Feel free to raise a PR should you wish to make any improvements.

# The Easy Way

I've provided a `Makefile` that wraps the AWS CLI calls
to make it easier to get up and running. It is assumed that
`make` is installed before you run the below steps.

Before you get started.
1. Take a copy of `environment.template` and update to match your environment
2. Login to ECR with `$(aws --profile personal --region us-east-1 ecr get-login --no-include-email)`. This is needed for the docker image push to ECR.

Now simply run
`make run`

The link for accessing the Wordpress site should be shown in the command output.

# The harder way

Below are the steps orchestrated by the `make run` shown above.

```
# Setup variables
AWS_ECR_NAME=YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
AWS_RDS_PASSWORD=SetToWhateverYouWant
AWS_STACK_NAME=wordpress01
AWS_SOURCE_CIDR=0.0.0.0/0
AWS_INSTANCE_TYPE=t2.micro
# Note: Must be created manually before execution
AWS_KEY_NAME=wordpress

# 1. Docker Build
docker build ${AWS_ECR_NAME}/secure-wordpress docker

# 2. Create Stack
aws --profile personal cloudformation create-stack --region us-east-1 \
--stack-name ${AWS_STACK_NAME} \
--capabilities CAPABILITY_IAM \
--template-body file://templates/cloudformation.json \
--parameters ParameterKey=DbPassword,ParameterValue=${AWS_RDS_PASSWORD}
ParameterKey=InstanceType,ParameterValue=${AWS_INSTANCE_TYPE} \
ParameterKey=KeyName,ParameterValue=${AWS_KEY_NAME} \
ParameterKey=SourceCidr,ParameterValue=${AWS_SOURCE_CIDR}

# 3. Wait for Cloud Formation stack creation to complete
./scripts/wait_for_cf.sh ${AWS_STACK_NAME}

# 4. Generate stack policy
./scripts/generate_encrypted_bucket_policy.sh ${AWS_STACK_NAME}

# 5. Write password to the bucket
./scripts/write_password_to_bucket.sh ${AWS_STACK_NAME}

# 6. Push Image
docker push ${AWS_ECR_NAME}/secure-wordpress

# 7. Run Wordpress Service
./scripts/create_ecs.sh ${AWS_STACK_NAME}
```

# The Hardest Way

See [this blog post](https://aws.amazon.com/blogs/security/how-to-manage-secrets-for-amazon-ec2-container-service-based-applications-by-using-amazon-s3-and-docker/).

# Destroying the stack

Ok, so you got it working? Cool!
But now, you want to save on AWS costs? Easy!
Simply run `make destroy`

# Known issues

I couldn't get access to the S3 bucket restricted to the ECS cluster VPC as per [this blog post](https://aws.amazon.com/blogs/security/how-to-manage-secrets-for-amazon-ec2-container-service-based-applications-by-using-amazon-s3-and-docker/). I've included the steps I followed in `scripts/generate_restricted_bucket_policy.sh`.  
