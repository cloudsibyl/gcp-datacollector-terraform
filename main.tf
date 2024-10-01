provider "google" {
  project = var.project_id
  region  = var.cloud_run_location
}

resource "google_organization_iam_member" "org_viewer" {
  for_each = toset([
    "roles/resourcemanager.organizationViewer",
    "roles/resourcemanager.folderViewer",
    "roles/viewer"  
  ])
  
  org_id = var.organization_id
  member = "serviceAccount:${var.service_account_email}"
  role   = each.key
}

resource "google_project_iam_member" "cloud_scheduler_permissions" {
  project = var.project_id
  member  = "serviceAccount:${var.service_account_email}"
  role    = "roles/cloudscheduler.admin"
}

resource "google_storage_bucket_iam_member" "bucket_access" {
  bucket = var.bucket_name
  member = "serviceAccount:${var.service_account_email}"
  role   = "roles/storage.objectCreator"
}

resource "google_project_iam_member" "cloud_run_invoker_permissions" {
  project = var.project_id
  member  = "serviceAccount:${var.service_account_email}"
  role    = "roles/run.invoker"
}

resource "google_cloud_run_v2_job" "job" {
  name               = var.cloud_run_job_name
  location           = var.cloud_run_location
  deletion_protection = false

  template {
    template {
      containers {
        image = "cloudsibyl/cloudsibyl-gcp-data-collector:latest"
        env {
          name  = "BUCKET_NAME"
          value = var.bucket_name
        }
        env {
          name  = "PROJECT_ID"
          value = var.project_id
        }
        env {
          name  = "DATASET_ID"
          value = var.dataset_id
        }
        env {
          name  = "COST_TABLE"
          value = var.cost_table
        }
        env {
          name  = "DETAILED_COST_TABLE"
          value = var.detailed_cost_table
        }
        resources {
          limits = {
            cpu    = "1000m"
            memory = "512Mi"
          }
        }
      }
      service_account = var.service_account_email
    }
  }

  lifecycle {
    ignore_changes = [
      launch_stage,
    ]
  }
}

resource "google_cloud_scheduler_job" "cloud_run_job_scheduler" {
  name        = "${var.cloud_run_job_name}-scheduler"
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
      service_account_email = var.service_account_email
      scope                 = "https://www.googleapis.com/auth/cloud-platform"
    }
  }

  depends_on = [
    google_project_iam_member.cloud_scheduler_permissions,
    google_project_iam_member.cloud_run_invoker_permissions
  ]
}