## 🚀 Secrets Generator App — AWS ECS Fargate Deployment Guide

This guide explains how to **build**, **deploy**, and **access** the `name-gen` app running on **AWS ECS (Fargate)** behind an **Application Load Balancer (ALB)** using **GitHub Actions** and **Terraform**.

---

## 🧱 Infrastructure Overview

**Services Used:**
- **Amazon ECR** – Stores your Docker images  
- **Amazon ECS (Fargate)** – Runs containers without managing servers  
- **Application Load Balancer (ALB)** – Routes HTTP traffic to your app  
- **GitHub Actions** – Builds & deploys the Docker image automatically  
- **IAM Roles** – Allow ECS to pull images and run tasks  

**App URL (after deploy):**
```

http://(your-alb-dns-name)

```

---

## 🪄 Prerequisites

1. **Installed Tools**
   - [Docker](https://docs.docker.com/get-docker/)
   - [Terraform](https://developer.hashicorp.com/terraform/downloads)
   - [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
   - [Git](https://git-scm.com/downloads)

2. **AWS Account**
   - With an **IAM user** that has permissions for ECR, ECS, ELB, IAM.
   - `AmazonECS_FullAccess`
   - `AmazonEC2ContainerRegistryFullAccess`
   - `ElasticLoadBalancingFullAccess`
   - `IAMReadOnlyAccess`
   - Store your AWS credentials in **GitHub Secrets**:
     - `AWS_ACCESS_KEY`
     - `AWS_SECRET_ACCESS_KEY`

3. **GitHub Repository**
   - Contains:
     - `Dockerfile`
     - `.github/workflows/deploy.yml`
     - `infra/` folder with Terraform setup

---


```
Automate-Deployment-of-Docker-Image-To-AWS-ECR
├─ deploy_to_ecr.sh
├─ Dockerfile
├─ ecs-task.json
├─ index.js
├─ main.tf
├─ outputs.tf
├─ package-lock.json
├─ package.json
├─ public
│  ├─ images
│  │  └─ whisper-img.jpg
│  └─ styles
│     └─ main.css
├─ Readme.md
├─ variables.tf
└─ views
   └─ index.ejs

```

## ⚙️ Step 1: Build and Test Locally

1. Build your Docker image:
    ```bash
   docker build -t secret-gen:latest .
    ```

2. Run it locally:

   ```bash
   docker run -p 3000:3000 secret-gen:latest
   ```

3. Open your browser and visit:

   ```
   http://localhost:3000
   ```

---

## ☁️ Step 2: Deploy AWS Infrastructure with Terraform

1. Navigate to your `project-repo` directory:

   ```bash
   cd infra
   ```

2. Initialize Terraform:

   ```bash
   terraform init
   ```

3. Apply the configuration:

   ```bash
   terraform apply -auto-approve
   ```

Terraform will create:

* ECR repository (`name-gen-repo`)
* ECS cluster & service (`name-gen-cluster`, `name-gen-service`)
* Application Load Balancer (ALB)
* Security groups, IAM roles, and networking

Once complete, Terraform will output:

```
alb_dns_name = name-gen-alb-xxxxxxx.us-east-1.elb.amazonaws.com
ecr_repository_url = $ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/name-gen-repo
```

---

## 🐳 Step 3: Push Docker Image to Amazon ECR

1. Authenticate Docker to ECR:

   ```bash
   aws ecr get-login-password --region us-east-1 \
   | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
   ```

2. Tag your image:

   ```bash
   docker tag name-gen:latest $ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/name-gen-repo:latest
   ```

3. Push the image:

   ```bash
   docker push $ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/name-gen-repo:latest
   ```

---

## 🤖 Step 4: Deploy via GitHub Actions (Automatic CI/CD)

Whenever you push to the **`main`** branch:

1. GitHub Actions will:

   * Build the Docker image
   * Push it to ECR
   * Update the ECS Task Definition
   * Deploy the new version to your ECS Fargate service

Your workflow file: `.github/workflows/deploy.yml`

---

## 🌐 Step 5: Access the App in Your Browser

1. Go to the **AWS Management Console → EC2 → Load Balancers**
2. Find the load balancer named `name-gen-alb`
3. Copy the **DNS name**, e.g.:

   ```
   name-gen-alb-123456789.us-east-1.elb.amazonaws.com
   ```
4. Open it in your browser:

   ```bash
   http://name-gen-alb-123456789.us-east-1.elb.amazonaws.com
   ```

🎉 Your app should now be running live on ECS Fargate!

---

## 🧩 Step 6: Useful Commands

### View ECS Services

```bash
aws ecs list-services --cluster name-gen-cluster
```

### Check Running Tasks

```bash
aws ecs list-tasks --cluster name-gen-cluster
```

### View Logs (via CloudWatch)

```bash
aws logs describe-log-groups
```

---

## 🧹 Step 7: Cleanup

When you’re done and want to remove all AWS resources:

```bash
cd infra
terraform destroy -auto-approve
```

This will remove the ALB, ECS cluster, ECR, and IAM roles.

---

## 🛠 Troubleshooting

| Issue                 | Possible Fix                                                            |
| --------------------- | ----------------------------------------------------------------------- |
| App not accessible    | Check ALB security group allows inbound port 80                         |
| Task stuck in PENDING | Ensure subnets and IAM role permissions are correct                     |
| Image not found       | Verify Docker image pushed to correct ECR repo                          |
| Access denied         | Double-check GitHub Secrets (`AWS_ACCESS_KEY`, `AWS_SECRET_ACCESS_KEY`) |

---

## 📘 Summary

| Component          | Name              |
| ------------------ | ----------------- |
| **AWS Region**     | us-east-1         |
| **ECR Repo**       | name-gen-repo     |
| **ECS Cluster**    | name-gen-cluster  |
| **ECS Service**    | name-gen-service  |
| **Container Port** | 300               |
| **Public Access**  | via ALB (port 80) |


---

**Author:** *EMMANUEL OWUSU-ADDAI*
