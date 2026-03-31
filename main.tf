provider "google" {
  project = "andes-terraform-lab"
  region  = var.region_servidor
}


terraform {
  backend "gcs" {
    bucket  = "tf-state-proyecto-andes-0869ac36" # Ejemplo: tf-state-proyecto-andes-a1b2c3d4
    prefix  = "terraform/state"
  }
}

resource "google_compute_network" "red_andes" {
  name                    = "vpc-andes"
  auto_create_subnetworks = false 
}



resource "google_compute_subnetwork" "subred_app" {
  name          = "subred-andes-app"
  region        = var.region_servidor
  ip_cidr_range = "10.0.1.0/24"
  network       = google_compute_network.red_andes.id 
}

output "ip_publica" {
  value = google_compute_instance.servidor_andes.network_interface[0].access_config[0].nat_ip
}

# Para obtener el nombre exacto
output "nombre_del_servidor" {
  value = google_compute_instance.servidor_andes.name
}

# Para obtener el ID único que le asigna Google
output "id_del_servidor" {
  value = google_compute_instance.servidor_andes.id

  
}

resource "google_compute_firewall" "regla_ssh" {
  name    = "permitir-ssh"
  network = google_compute_network.red_andes.name

  allow {
    protocol = "tcp"
    ports    = ["22", "80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"]
}


variable "tipo_servidor" {
  description = "El tipo de máquina virtual"
  type = string
  default = "e2-micro"
}

variable "zona_servidor" {
  description = "Zona del servidor"
  type        = string
  default     = "us-central1-a" # <--- Cambia a Iowa
}

variable "region_servidor" {
  description = "Región de los recursos"
  type        = string
  default     = "us-central1"   # <--- Cambia a Iowa
}

resource "google_compute_address" "ip_estatica" {
  name   = "ipv4-estatica"
  region = var.region_servidor
  lifecycle {
    prevent_destroy = true
  }
}

resource "google_compute_instance" "servidor_andes" {
  name         = "servidor-andes"
  machine_type = var.tipo_servidor
  zone         = var.zona_servidor
  tags         = ["web-server"]
  
  metadata_startup_script = <<-EOF
    #!/bin/bash
    # 1. Dar 30 segundos de ventaja al OS para liberar los bloqueos internos
    sleep 30
    
    # 2. Actualizar e instalar forzando el modo no interactivo
    DEBIAN_FRONTEND=noninteractive apt-get update -y
    DEBIAN_FRONTEND=noninteractive apt-get install -y nginx
    
    # 3. Crear el archivo web directamente
    echo '<!DOCTYPE html><html><head><meta charset="UTF-8"><title>Proyecto Andes</title></head><body><div style="text-align: center; padding: 50px;"><h1>🏔️ Bienvenidos al Proyecto Andes</h1><p>Desplegado 100% con Terraform de forma automática.</p></div></body></html>' > /var/www/html/index.html
    
    # 4. Asegurar que el servicio arranque
    systemctl restart nginx
  EOF 

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subred_app.name
    access_config {
      nat_ip = google_compute_address.ip_estatica.address
    }
  }
}

# Creamos el Bucket para guardar el estado de Terraform
resource "google_storage_bucket" "estado_terraform_andes" {
  name          = "tf-state-proyecto-andes-${random_id.bucket_suffix.hex}" # Nombre único global
  location      = "US" # Puede ser regional o multi-regional
  force_destroy = false # Protección extra: no deja borrar el bucket si tiene archivos

  versioning {
    enabled = true # ¡Súper importante! Guarda versiones viejas por si algo sale mal
  }
}

# Necesitamos un ID único porque los nombres de los buckets son globales en todo Google
resource "random_id" "bucket_suffix" {
  byte_length = 4
}