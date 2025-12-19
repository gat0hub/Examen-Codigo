provider "aws" {
  region     = "us-east-1"
  access_key =
  secret_key = 
  token      =
}
 
 
# Crear la subred
resource "aws_subnet" "main" {
  vpc_id            = "vpc-0c968fce5c360ecb5"
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"
}
 
# Crear el gateway de Internet
resource "aws_internet_gateway" "main" {
  vpc_id = "vpc-0c968fce5c360ecb5"
}
 
# Crear la ruta principal
resource "aws_route_table" "main" {
  vpc_id = "vpc-0c968fce5c360ecb5"
 
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}
 
# Asignar la subred a la ruta
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}
 
# Crear el grupo de seguridad
resource "aws_security_group" "allow_http" {
  vpc_id = "vpc-0c968fce5c360ecb5"
  ingress {
    from_port   = 80
    to_port     = 80
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
 
# Crear las instancias EC2
resource "aws_instance" "app1" {
  ami                         = "ami-06c68f701d8090592" # Amazon Linux 2 AMI (HVM), SSD Volume Type
  instance_type               = "t2.micro"
  #security_groups             = [aws_security_group.allow_http.name]
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.main.id
  tags = {
    Name = "AppServer1"
  }
 
  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y httpd",
      "sudo systemctl start httpd",
      "sudo systemctl enable httpd"
    ]
 
    connection {
      type        = "ssh"
      user        = "ec2-user"
      host        = self.public_ip
    }
  }
}
 
resource "aws_instance" "app2" {
  ami                         = "ami-06c68f701d8090592" # Amazon Linux 2 AMI (HVM), SSD Volume Type
  instance_type               = "t2.micro"
  #security_groups             = [aws_security_group.allow_http.name]
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.main.id
  tags = {
    Name = "AppServer2"
  }
 
  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y httpd",
      "sudo systemctl start httpd",
      "sudo systemctl enable httpd"
    ]
 
    connection {
      type        = "ssh"
      user        = "ec2-user"
      host        = self.public_ip
    }
  }
}
 
resource "aws_instance" "app3" {
  ami                         = "ami-06c68f701d8090592" # Amazon Linux 2 AMI (HVM), SSD Volume Type
  instance_type               = "t2.small"
  #security_groups             = [aws_security_group.allow_http.name]
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.main.id
  tags = {
    Name = "AppServer3"
  }
}
 
resource "aws_instance" "app4" {
  ami                         = "ami-06c68f701d8090592" # Amazon Linux 2 AMI (HVM), SSD Volume Type
  instance_type               = "t2.small"
  #security_groups             = [aws_security_group.allow_http.name]
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.main.id
  tags = {
    Name = "AppServer4"
  }
}
 
# Crear la base de datos RDS
resource "aws_db_instance" "default" {
  allocated_storage    = 20
  engine               = "aurora-mysql"
  instance_class       = "db.t2.micro"
  identifier           = "mydatabase"
  username             = "root"
  password             = "mypassword"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
  publicly_accessible  = false
  db_subnet_group_name = aws_db_subnet_group.main.name
}
 
resource "aws_db_subnet_group" "main" {
  name       = "main"
  subnet_ids = [aws_subnet.main.id]
 
  tags = {
    Name = "Main DB subnet group"
  }
}

