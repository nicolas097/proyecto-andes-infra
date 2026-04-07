# 1. Reservar un bloque de IPs privadas exclusivas para la base de datos
resource "google_compute_global_address" "rango_ip_privado" {
  name = "rango_ip_privado-andes"
  purpose = "VPC_PEERING"
  address_type = "INTERNAL"
  prefix_length = 16
  network = google_compute_network.red_andes.id
}

#2. Crear el puente (Peering) entre tu red (Poryecto Andes) y red interna de google 

resource "google_service_networking_connection" "conexion_privada" {
    network = google_compute_network.red_andes.id
    service = "servicenetworking.googleapis.com"
    reserved_peering_ranges = [google_compute_global_address.rango_ip_privado.name]
}


#3 Crear instancia de postgreSQL

resource "google_sql_database_instance" "postgres_andes" {
  name = "bd-postgres-andes-${random_id.bucket_suffix.hex}"
  database_version = "POSTGRES_15"
  region = var.region_servidor

  deletion_protection = false

  settings {
    tier = "db-f1-micro"
    # CONFIGURACIÓN DE SEGURIDAD: Apagar IP pública y conectarla al túnel
      ip_configuration {
        ipv4_enabled = false
        private_network = google_compute_network.red_andes.id

      }

  }

  #Semaforo 
  depends_on = [ google_service_networking_connection.conexion_privada ]
}


