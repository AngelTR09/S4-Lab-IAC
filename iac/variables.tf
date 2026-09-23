variable "dev_web_port" {
  description = "Puerto publicado en el host para web-dev. Override en terraform.tfvars."
  type        = number
  default     = 4001
}

variable "dev_api_port" {
  description = "Puerto publicado en el host para api-dev. Override en terraform.tfvars."
  type        = number
  default     = 4002
}

variable "dev_db_port" {
  description = "Puerto publicado en el host para bd-dev. Override en terraform.tfvars."
  type        = number
  default     = 4003
}

variable "qa_web_port" {
  description = "Puerto publicado en el host para web-qa. Override en terraform.tfvars."
  type        = number
  default     = 5001
}

variable "qa_api_port" {
  description = "Puerto publicado en el host para api-qa. Override en terraform.tfvars."
  type        = number
  default     = 5002
}

variable "qa_db_port" {
  description = "Puerto publicado en el host para bd-qa. Override en terraform.tfvars."
  type        = number
  default     = 5003
}

variable "frontend_build_path" {
  description = "Ruta al directorio con el Dockerfile del frontend (nginx)."
  type        = string
  default     = "../frontend"
}

variable "backend_build_path" {
  description = "Ruta al directorio con el Dockerfile del backend (node)."
  type        = string
  default     = "../backend"
}

variable "postgres_image" {
  description = "Imagen oficial de PostgreSQL a usar en ambos entornos."
  type        = string
  default     = "postgres:17"
}

variable "db_name" {
  description = "Nombre de la base de datos Postgres. Se define en terraform.tfvars (ver terraform.tfvars.example)."
  type        = string
}

variable "db_user" {
  description = "Usuario de la base de datos Postgres. Se define en terraform.tfvars (ver terraform.tfvars.example)."
  type        = string
}

variable "db_password" {
  description = "Password de la base de datos Postgres. Se define en terraform.tfvars (ver terraform.tfvars.example); no lleva default para no dejar credenciales en el código."
  type        = string
  sensitive   = true
}

# Reconstruye el mapa por entorno (web_port/api_port/db_port por clave dev/qa)
# a partir de las variables escalares de arriba, para poder iterar con un
# único for_each = local.environments en los *-server.tf.
locals {
  environments = {
    dev = {
      web_port = var.dev_web_port
      api_port = var.dev_api_port
      db_port  = var.dev_db_port
    }
    qa = {
      web_port = var.qa_web_port
      api_port = var.qa_api_port
      db_port  = var.qa_db_port
    }
  }
}
