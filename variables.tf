variable "aws_region" {
  type        = string
  default     = "ca-central-1"
  description = "Región de AWS para el despliegue"
}

variable "proyecto" {
  type        = string
  default     = "casino"
  description = "Nombre del proyecto para la nomenclatura"
}

variable "operacion" {
  type        = string
  default     = "prod"
  description = "Ambiente u operación (ej: prod, dev, qa)"
}