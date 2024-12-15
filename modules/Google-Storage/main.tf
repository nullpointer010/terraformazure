# Crear un recurso google_storage_bucket para almacenar imágenes en Google Storage
#
# Crear en el bucket anteior dos recursos google_storage_bucket_object
# (uno para cada imagen de la carpeta ./images)
# Configurar la propiedad source desde la raíz del proyecto (./images/<imagen.jpg>)
#
# Definir una regla de acceso para objeto creado de forma que sea público 
# Configurar google_storage_object_access_control así
#   role   = "READER"
#   entity = "allUsers"

resource "google_storage_bucket" "image_bucket" {
  name     = var.gcp_bucket_name
  location = "US"                  # ver regiones
  storage_class = "STANDARD"       

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 365                    # Elimina objetos después de un año
    }
  }
}

resource "google_storage_bucket_object" "image1" {
  name   = "el_enigma_de_la_habitacion_622.jpg"
  bucket = google_storage_bucket.image_bucket.name
  source = "./images/el_enigma_de_la_habitacion_622.jpg"  # Ruta 
}

resource "google_storage_bucket_object" "image2" {
  name   = "una_historia_de_espana.jpg"
  bucket = google_storage_bucket.image_bucket.name
  source = "./images/una_historia_de_espana.jpg"  # Ruta
}

resource "google_storage_object_access_control" "image1_access" {
  bucket = google_storage_bucket.image_bucket.name
  object = google_storage_bucket_object.image1.name
  role   = "READER"
  entity = "allUsers"
}

resource "google_storage_object_access_control" "image2_access" {
  bucket = google_storage_bucket.image_bucket.name
  object = google_storage_bucket_object.image2.name
  role   = "READER"
  entity = "allUsers"
}
