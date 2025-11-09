output "alb_dns_name" {
  value = aws_lb.secret_gen_alb.dns_name
}

output "ecr_repository_url" {
  value = aws_ecr_repository.secret_gen_repo.repository_url
}
