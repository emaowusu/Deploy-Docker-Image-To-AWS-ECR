terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.3.0"
}

provider "aws" {
  region = var.region
}

# --- ECR Repository ---
resource "aws_ecr_repository" "secret_gen_repo" {
  name                 = var.ecr_repo_name
  image_tag_mutability = "MUTABLE"
}

# --- ECS Cluster ---
resource "aws_ecs_cluster" "secret_gen_cluster" {
  name = var.cluster_name
}

# --- IAM Role for ECS Task Execution ---
data "aws_iam_policy_document" "ecs_task_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_lb_target_group" "secret_gen_tg" {
  name     = "secret-gen-tg"
  port     = var.container_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id
  target_type = "ip"

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}


# --- VPC & Networking (using default VPC) ---
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# --- Security Group ---
resource "aws_security_group" "secret_gen_sg" {
  name        = "secret-gen-sg"
  description = "Allow HTTP access"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- Application Load Balancer ---
resource "aws_lb" "secret_gen_alb" {
  name               = "secrets-gen-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.secret_gen_sg.id]
  subnets            = data.aws_subnets.default.ids
}

# resource "aws_lb_target_group" "secret-gen_tg" {
#   name        = "secrets-gen-tg"
#   port        = var.container_port
#   protocol    = "HTTP"
#   vpc_id      = data.aws_vpc.default.id
#   target_type = "ip"
#   health_check {
#     path                = "/"
#     interval            = 30
#     timeout             = 5
#     healthy_threshold   = 3
#     unhealthy_threshold = 3
#   }
# }

resource "aws_lb_listener" "secret_gen_listener" {
  load_balancer_arn = aws_lb.secret_gen_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.secret_gen_tg.arn
  }
}

# --- ECS Task Definition ---
resource "aws_ecs_task_definition" "secret_gen_task" {
  family                   = "secret-gen-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = templatefile("${path.module}/ecs-task-def.json", {
    ecr_image_url  = "${aws_ecr_repository.secret_gen_repo.repository_url}:latest"
    container_port = var.container_port
    region         = var.region
  })
}

# --- ECS Service ---
resource "aws_ecs_service" "secret_gen_service" {
  name            = var.service_name
  cluster         = aws_ecs_cluster.secret_gen_cluster.id
  task_definition = aws_ecs_task_definition.secret_gen_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.secret_gen_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.secret_gen_tg.arn
    container_name   = "secret-gen-container"
    container_port   = var.container_port
  }

  depends_on = [aws_lb_listener.secret_gen_listener]
}
