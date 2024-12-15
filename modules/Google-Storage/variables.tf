# Definir 3 variables
# * gcp_username inicializada con el nombre de usuario en GCP
# * gcp_project inicializada con el nombre del proyecto en GCP
# * gcp_bucket_name inicializada con el nombre del bucket a crear en Google Storage

variable "gcp_username" {
  description = "El nombre de usuario en Google Cloud Platform (GCP)."
  default     = "mk3500" 
}

variable "gcp_project" {
  description = "El ID del proyecto en Google Cloud Platform (GCP)."
  default     = "mk3500" 
}

variable "gcp_bucket_name" {
  description = "El nombre del bucket a crear en Google Storage."
  default     = "imagen_buckets"
}
