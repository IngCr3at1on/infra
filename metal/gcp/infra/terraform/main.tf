# Create a GCS Bucket
resource "google_storage_bucket" "lab_ingcr3at1on_com_infra_terraform-state" {
  project       = var.gcp_project
  name          = var.bucket-name
  location      = var.gcp_region
  force_destroy = true
  storage_class = var.storage-class
  versioning {
    enabled = true
  }
}