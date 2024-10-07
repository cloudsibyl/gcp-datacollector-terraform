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

variable "cloud_run_location" {
  description = "The location/region where the Cloud Run job will be deployed."
  type        = string
}
