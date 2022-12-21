
variable "subnet_id" {
  type = string
  description = "Id of the subnet where EC2 need to be deployed"
}

resource "aws_instance" "vm1" {
  ami                         = "ami-08bd8e5c51334492e"
  associate_public_ip_address = true
  availability_zone           = "ap-south-1a"
  instance_type               = "t2.micro"
  subnet_id                   = var.subnet_id
}