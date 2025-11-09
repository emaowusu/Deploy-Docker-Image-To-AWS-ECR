#!/bin/bash
 set -e
 AWS_REGION="us-east-1"
 AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
 ECR_REPO_NAME="secret-gen-repo"
 # 1. Create repo if not exists
 aws ecr describe-repositories --repository-names $ECR_REPO_NAME --region $AWS_REGION >/dev/null 
aws ecr create-repository --repository-name $ECR_REPO_NAME --region $AWS_REGION
 # 2. Authenticate Docker to ECR
 aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $
 # 3. Build Docker image
 docker build -t ${ECR_REPO_NAME}:latest .
 # 4. Tag and push image
 docker tag ${ECR_REPO_NAME}:latest ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_R
 docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:latest

