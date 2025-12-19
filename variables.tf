# ---------------------------------------------------------
# VARIABLES BÁSICAS
# ---------------------------------------------------------
variable "aws_region" {
  default = "us-east-1"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

# ---------------------------------------------------------
# MEJORA: PARAMETRIZACIÓN DE ENTORNO
# ---------------------------------------------------------
variable "project_name" {
  description = "Nombre del proyecto (se usará para etiquetar)"
  type        = string
  default     = "MiProyectoWeb"
}

variable "environment" {
  description = "Entorno de despliegue (dev, prod, test)"
  type        = string
  default     = "dev"
}

# ---------------------------------------------------------
# MEJORA: CONDICIONAL PARA CREAR RECURSOS
# ---------------------------------------------------------
variable "create_database" {
  description = "Booleano para decidir si crear la BD o no (true/false)"
  type        = bool
  default     = true
}

variable "db_password" {
  description = "Password de la BD (Solo necesaria si create_database es true)"
  type        = string
  sensitive   = true
  default     = "terraform123" # Pongo default solo para facilitar tu prueba rapida
}

variable "instance_type" {
  default = "t2.micro"
}

variable "instance_count" {
  default = 2
}
