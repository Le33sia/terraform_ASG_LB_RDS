# RDS
resource "aws_db_instance" "RDS" {
  allocated_storage    = 10
  engine               = "mysql"
  engine_version       = "8.0.33"
  instance_class       = "db.t3.micro"
  identifier           = "database-1"
  db_name              = var.database_dbname
  username             = var.database_username
  password             = random_password.password.result
  db_subnet_group_name = aws_db_subnet_group.rds-subnet-group.name
  parameter_group_name = "default.mysql8.0"
  multi_az             = "false"
  vpc_security_group_ids = [aws_security_group.rds-SG.id]
  storage_type         = "gp2"
  skip_final_snapshot  = true
}
resource "aws_db_subnet_group" "rds-subnet-group" {
    name = "rds-subnet-group"
    description = "RDS subnet group"
    subnet_ids = [aws_subnet.Private_subnet1.id, aws_subnet.Private_subnet2.id]
}

#SECRETS_MANAGER
resource "aws_secretsmanager_secret" "secretdb" {
  name = "secret2"
}
resource "aws_secretsmanager_secret_version" "secretdb" {
  secret_id     = aws_secretsmanager_secret.secretdb.id
  secret_string = jsonencode({
    username = var.database_username
    password = random_password.password.result
    host     = aws_db_instance.RDS.endpoint
    dbname   = var.database_dbname
  })
}
resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "_%@"
}
 

 
