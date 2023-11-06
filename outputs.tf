output "rds_endpoint" {
  value = aws_db_instance.RDS.endpoint
  sensitive = true
}

output "secrets_manager_secret_arn" {
  value = aws_secretsmanager_secret.secretdb.arn 
  sensitive = true
}

output "ami_id" {
  value = data.aws_ami.ami.id
}
