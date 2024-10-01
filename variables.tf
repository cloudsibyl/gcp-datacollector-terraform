variable "project_id" {
  description = "The ID of the project in which to create resources."
  type        = string
}

variable "organization_id" {
  description = "The ID of the organization where the roles will be applied."
  type        = string
}

variable "bucket_name" {
  description = "The name of the GCS bucket to be used by the Cloud Run job."
  type        = string
}

variable "dataset_id" {
  description = "The ID of the BigQuery dataset to be used by the Cloud Run job."
  type        = string
}

variable "cost_table" {
  description = "The name of the BigQuery table to be used by the Cloud Run job."
  type        = string
}

variable "detailed_cost_table" {
  description = "The name of the BigQuery table to be used by the Cloud Run job."
  type        = string
}

variable "service_account_email" {
  description = "The email of the service account to be used by the Cloud Run job."
  type        = string
}

variable "cloud_run_job_name" {
  description = "The name of the Cloud Run job to be created."
  type        = string
}

variable "cloud_run_location" {
  description = "The location/region where the Cloud Run job will be deployed."
  type        = string
}
