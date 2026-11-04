# Phase 0 — Foundations (hands-on)

The reading is in [docs/00-foundations.md](../docs/00-foundations.md). This folder is the hands-on
part: three exercises that get you deploying to all three clouds with Terraform.

**Milestone for Phase 0:** you can deploy and destroy the same thing on AWS, Azure and GCP, explain
what was different on each, and your Terraform state lives in remote storage on each cloud.

---

## Checklist

### Week 1 — Accounts and safety
- [ ] Create an **AWS** account → enable MFA on the root user → set up **IAM Identity Center** and an admin user → stop using root
- [ ] Create an **Azure** account → enable MFA
- [ ] Create a **Google Cloud** account → create a project for this repo (e.g. `jaival-cloud-lab`)
- [ ] **Budget alert on each cloud** (e.g. $10/month, alerts at 50/80/100%) — do this *before* anything else
  - AWS: Billing → Budgets → Create budget
  - Azure: Cost Management → Budgets
  - GCP: Billing → Budgets & alerts
- [ ] Install the tools: Git, Terraform (≥ 1.10), AWS CLI v2, Azure CLI, gcloud CLI, Docker, jq, VS Code (+ HashiCorp Terraform extension)
- [ ] Log in and check everything:
  ```bash
  aws configure sso
  aws sso login
  az login
  export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
  gcloud auth login
  gcloud auth application-default login
  gcloud config set project <YOUR_PROJECT_ID>
  ./scripts/check-tools.sh
  ```

### Weeks 1–3 — Read and practise
Work through [docs/00-foundations.md](../docs/00-foundations.md) and the
[multi-cloud service map](../docs/multi-cloud-service-map.md). Do the "you're ready when…" checks.

### Weeks 2–4 — The exercises below

---

## Exercise 1 — Hello storage (all three clouds)

Folder: [`01-hello-storage/`](01-hello-storage/). The same thing — a private, versioned, encrypted
storage bucket — built three ways. Each folder takes the **same variables** (`project`, `env`,
`region`, `owner`) and returns the **same outputs** (`bucket_name`, `bucket_url`). That's the pattern
every project in this repo follows.

```bash
cd foundations/01-hello-storage/aws
terraform init
terraform plan        # read the plan before applying!
terraform apply
echo "hello from aws" > hello.txt
aws s3 cp hello.txt "$(terraform output -raw bucket_url)/"
terraform destroy
```

```bash
cd ../azure
terraform init && terraform apply
# Uploading with --auth-mode login uses your Entra ID identity (no keys).
# First grant yourself the data-plane role — being Owner of the subscription is NOT enough:
az role assignment create --role "Storage Blob Data Contributor" \
  --assignee "$(az ad signed-in-user show --query id -o tsv)" \
  --scope "$(az storage account show -n <ACCOUNT_NAME> --query id -o tsv)"
echo "hello from azure" > hello.txt
az storage blob upload --auth-mode login --account-name <ACCOUNT_NAME> -c hello -f hello.txt
terraform destroy
```

```bash
cd ../gcp
terraform init
terraform apply -var gcp_project_id=<YOUR_PROJECT_ID>
echo "hello from gcp" > hello.txt
gcloud storage cp hello.txt "$(terraform output -raw bucket_url)/"
terraform destroy -var gcp_project_id=<YOUR_PROJECT_ID>
```

**Questions to answer in your notes** (start `foundations/notes.md`):
1. Why does Azure need a resource group and a storage account before you get a "bucket"?
2. On Azure, why could you not upload until you gave yourself *Storage Blob Data Contributor*, even as Owner? (Hint: **control plane vs data plane** — a key Azure concept.)
3. Why does the GCP config need `gcp_project_id` while AWS and Azure don't?
4. Which cloud blocks public access by default, and how did each config make it explicit?
5. Open each `terraform.tfstate` before destroying. What's inside? Why must it never go into Git?

## Exercise 2 — Remote state storage (all three clouds)

Folder: [`02-state-backend/`](02-state-backend/). Creates the storage that holds Terraform state for
**every later project**, so keep these deployed (they cost cents per month).

```bash
cd foundations/02-state-backend/aws   && terraform init && terraform apply && terraform output -raw backend_config
cd ../azure                          && terraform init && terraform apply && terraform output -raw backend_config
cd ../gcp                            && terraform init && terraform apply -var gcp_project_id=<YOUR_PROJECT_ID> && terraform output -raw backend_config
```

These bootstrap configs use **local** state (the remote storage doesn't exist yet — chicken and egg).
Their `terraform.tfstate` files are git-ignored. Back them up somewhere safe, such as a password manager.
They have `prevent_destroy` set because deleting state storage makes Terraform forget everything it built.

**Then:** add the printed `backend` block to your Exercise 1 config, run `terraform init -migrate-state`,
and watch the state move into the cloud. Try running `terraform apply` from two terminals at once to
see **state locking** in action.

**Questions:**
1. How does each backend lock state? (S3 lock file / blob lease / GCS lock file.)
2. Why is versioning enabled on all three?
3. Why does the Azure backend use `use_azuread_auth = true`, and what would the alternative be?

## Exercise 3 — Your first CI check

[`.github/workflows/terraform-checks.yml`](../.github/workflows/terraform-checks.yml) already runs
`terraform fmt -check` and `terraform validate` on every folder for each pull request. Try it:

1. Create a branch, mis-indent a line in any `.tf` file, open a pull request → watch it fail.
2. Run `terraform fmt -recursive`, push → watch it pass.
3. Turn on **branch protection** for `main` (Settings → Branches): require a PR and the `terraform-checks` jobs to pass.

---

✅ **Phase 0 done when:** all checklist boxes are ticked, `notes.md` answers the questions above, and
the three state backends are deployed. Next: [project 09](../projects/09-secrets-free-cicd-oidc/).
