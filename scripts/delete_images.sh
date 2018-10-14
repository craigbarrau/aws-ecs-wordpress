echo "Deleting latest image"
echo "WARNING: If you have more than one latest image, you will need to delete them manually"
echo "  or, raise a PR to improve this script."
aws --profile personal \
--region us-east-1 ecr batch-delete-image --image-ids imageTag=latest \
--repository-name secure-wordpress
