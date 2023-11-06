variable "vpc_cidr" {
  default = "172.16.0.0/16"
}
variable "Public_subnet_cidr" {
  default = "172.16.0.0/26"
}
variable "Public_subnet2_cidr" {
  default = "172.16.0.64/26"
}
variable "Private_subnet1_cidr" {
  default = "172.16.0.128/26"
}
variable "Private_subnet2_cidr" {
  default = "172.16.0.192/26"
}
variable "database_username" {
 # type    = string
 # default = "admin"
}
variable "database_dbname" {
 # type    = string
 # default = "demodb"
}
