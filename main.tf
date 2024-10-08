provider "google" {
  project = var.project_id
  region  = var.cloud_run_location
}

# Generate a 5-digit random number
resource "random_id" "sa_suffix" {
  byte_length = 2
}

# Create a new service account with a dynamic ID based on a 5-digit random number
resource "google_service_account" "datacollector_sa" {
  account_id   = "cloudsibyl-${random_id.sa_suffix.hex}-sa"
  display_name = "Cloudsibyl Data Collector Service Account"
}

# Create a new storage bucket with uniform bucket-level access
resource "google_storage_bucket" "bucket" {
  name     = var.bucket_name
  location = var.cloud_run_location

  uniform_bucket_level_access = true
}

# Assign Viewer roles (read-only access to organization, folder, and other services)
resource "google_organization_iam_member" "org_viewer" {
  for_each = toset([
    "roles/resourcemanager.organizationViewer",
    "roles/resourcemanager.folderViewer",
    "roles/viewer"
  ])
  
  org_id = var.organization_id
  member = "serviceAccount:${google_service_account.datacollector_sa.email}"
  role   = each.key
}

# Assign BigQuery Data Editor role (allow creating, deleting, and reading tables)
resource "google_project_iam_member" "bigquery_editor" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.datacollector_sa.email}"
}

# Cloud Scheduler admin permissions
resource "google_project_iam_member" "cloud_scheduler_permissions" {
  project = var.project_id
  member  = "serviceAccount:${google_service_account.datacollector_sa.email}"
  role    = "roles/cloudscheduler.admin"
}

# Assign permissions for storage bucket access (object creator and object admin)
resource "google_storage_bucket_iam_member" "bucket_access" {
  bucket = google_storage_bucket.bucket.name
  member = "serviceAccount:${google_service_account.datacollector_sa.email}"
  role   = "roles/storage.objectCreator"
}

resource "google_storage_bucket_iam_member" "bucket_access_object_admin" {
  bucket = google_storage_bucket.bucket.name
  member = "serviceAccount:${google_service_account.datacollector_sa.email}"
  role   = "roles/storage.objectAdmin"
}

# Assign permissions for Cloud Run invocation
resource "google_project_iam_member" "cloud_run_invoker_permissions" {
  project = var.project_id
  member  = "serviceAccount:${google_service_account.datacollector_sa.email}"
  role    = "roles/run.invoker"
}

# Cloud Run job using the new service account
resource "google_cloud_run_v2_job" "job" {
  name               = "cloudsibyl-datacollector-run-job"
  location           = var.cloud_run_location
  deletion_protection = false

  template {
    template {
      containers {
        image = "cloudsibyl/cloudsibyl-gcp-data-collector:latest"
        env {
          name  = "BUCKET_NAME"
          value = google_storage_bucket.bucket.name
        }
        env {
          name  = "PROJECT_ID"
          value = var.project_id
        }
        env {
          name  = "DATASET_ID"
          value = var.dataset_id
        }
        resources {
          limits = {
            cpu    = "1000m"
            memory = "512Mi"
          }
        }
      }
      # Use the newly created service account
      service_account = google_service_account.datacollector_sa.email
    }
  }

  lifecycle {
    ignore_changes = [
      launch_stage,
    ]
  }
}

# Cloud Scheduler to trigger Cloud Run jobs using the service account
resource "google_cloud_scheduler_job" "cloud_run_job_scheduler" {
  name        = "cloudsibyl-datacollector-run-job-scheduler"
  description = "Scheduled trigger for Cloud Run job"
  schedule    = "30 20 * * *"  # Runs every night at 8:30 PM
  time_zone   = "Etc/UTC"  # Set to UTC
  region      = var.cloud_run_location  # Explicitly set the region

  http_target {
    http_method = "POST"
    uri         = "https://${var.cloud_run_location}-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/${var.project_id}/jobs/${google_cloud_run_v2_job.job.name}:run"

    headers = {
      "User-Agent" = "Google-Cloud-Scheduler"
    }

    oauth_token {
      service_account_email = google_service_account.datacollector_sa.email
      scope                 = "https://www.googleapis.com/auth/cloud-platform"
    }
  }

  depends_on = [
    google_project_iam_member.cloud_scheduler_permissions,
    google_project_iam_member.cloud_run_invoker_permissions
  ]
}
