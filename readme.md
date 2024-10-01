1- terraform init
```markdown
## Terraform Commands

To run the Terraform plan or apply commands, use the following format:

```sh
terraform [plan/apply] \
    -var="organization_id=YOUR_ORG_ID" \
    -var="project_id=cloudsibyl-integration" \
    -var="cloud_run_job_name=cloudsibyl-datacollector-run-job" \
    -var="bucket_name=cloudsibyl-metadata-collector" \
    -var="cloud_run_location=YOUR_LOCATION" \
    -var="service_account_email=YOUR_SERVICE_ACCOUNT_PRINCIPLE" \
    -var="dataset_id=YOUR-COST-DATASET-ID" \
    -var="cost_table=YOUR-COST-TABLE-NAME-IN-DATASET" \
    -var="detailed_cost_table=YOUR-DETAILED-COST-TABLE-NAME"
```
```
