provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {
  state = "available"
}


locals {
 
  project_id = lower(var.project_name)
  
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
  
  
  vpc_name = format("%s-%s-vpc", var.environment, local.project_id)
}


resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  
  
  tags = merge(local.common_tags, {
    Name = local.vpc_name
  })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = merge(local.common_tags, { Name = "${local.project_id}-igw" })
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = { Name = "${local.project_id}-rt" }
}

resource "aws_subnet" "public_subnets" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = format("%s-subnet-%d", local.project_id, count.index + 1)
  })
}

resource "aws_route_table_association" "a" {
  count          = 2
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.main.id
}


resource "aws_security_group" "lb_sg" {
  name        = "${local.project_id}-lb-sg"
  description = "SG para Load Balancer"
  vpc_id      = aws_vpc.main.id

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

resource "aws_security_group" "app_sg" {
  name        = "${local.project_id}-app-sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
  }
  
  ingress {
    from_port   = 22
    to_port     = 22
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


resource "aws_lb" "app_lb" {
  name               = "${local.project_id}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = aws_subnet.public_subnets[*].id
  
  tags = local.common_tags
}

resource "aws_lb_target_group" "app_tg" {
  name     = "${local.project_id}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path = "/"
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}


resource "aws_instance" "app_servers" {
  count = var.instance_count

  ami                    = "ami-06c68f701d8090592" 
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public_subnets[count.index % 2].id
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Servidor ${count.index + 1} - ${var.environment}</h1>" > /var/www/html/index.html
              EOF

  tags = merge(local.common_tags, {
    Name = "${local.project_id}-server-${count.index + 1}"
  })
}

resource "aws_lb_target_group_attachment" "attach" {
  count            = var.instance_count
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = aws_instance.app_servers[count.index].id
  port             = 80
}


resource "aws_db_subnet_group" "rds_subnet_group" {
  
  count = var.create_database ? 1 : 0
  
  name       = "${local.project_id}-db-subnet-group"
  subnet_ids = aws_subnet.public_subnets[*].id
}

resource "aws_db_instance" "default" {
  
  count = var.create_database ? 1 : 0

  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "8.0"           # <--- CAMBIO: Actualizado a 8.0
  instance_class       = "db.t3.micro"   # <--- CAMBIO: t3 es la generación actual soportada
  db_name              = "mydatabase"
  username             = "admin"
  password             = var.db_password
  parameter_group_name = "default.mysql8.0" # <--- CAMBIO: Debe coincidir con la versión 8.0
  skip_final_snapshot  = true
  publicly_accessible  = false
  
  # Referenciamos el grupo de subredes
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group[0].name
  
  tags = local.common_tags
}


output "alb_dns" {
  value = aws_lb.app_lb.dns_name
}

output "db_status" {
 
  value = var.create_database ? "Base de datos creada en RDS" : "Base de datos NO creada (ahorro de costos)"
}


