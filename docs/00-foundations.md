# 00 · Foundations — what to know before project 1

You don't need to master all of this first. Learn it well enough to follow along, then deepen it
while building. Each section ends with a **"you're ready when…"** check.

The examples below use Azure (the lead cloud in this repo). Section 0 sets up all three clouds, and the
[multi-cloud service map](multi-cloud-service-map.md) gives the AWS and GCP equivalent of every concept
here. Read the two side by side.

---

## 0. Set up all three clouds

| | AWS | Azure | GCP |
|---|---|---|---|
| Sign up | AWS account (free tier / credits for new accounts) | Azure free account (credit for 30 days) | Google Cloud free trial (credit for 90 days) |
| First security steps | MFA on root user, **never use root** day-to-day; enable IAM Identity Center and create an admin user | MFA on your account; Entra ID Security Defaults | MFA on your Google account; create a dedicated project per experiment |
| Billing alert | AWS Budgets | Cost Management budget | Cloud Billing budget |
| CLI | `aws` | `az` | `gcloud` |
| Log in | `aws configure sso` then `aws sso login` | `az login` | `gcloud auth login` + `gcloud auth application-default login` |
| Terraform provider | `hashicorp/aws` | `hashicorp/azurerm` | `hashicorp/google` |

Same task on each cloud — create and delete a storage bucket:
```bash
aws s3 mb s3://jaival-test-$RANDOM --region ap-south-1
az storage account create -n jaivaltest$RANDOM -g rg-test -l centralindia --sku Standard_LRS
gcloud storage buckets create gs://jaival-test-$RANDOM --location=asia-south1
```
Notice the differences already: S3 and GCS bucket names are **globally unique**; Azure needs a storage
*account* (also globally unique, lowercase, no dashes) inside a resource group before you can create containers.

✅ *You're ready when* all three CLIs are logged in, budgets are set, and you've created and deleted a bucket on each.

---

## 1. How Azure is organised

```
Microsoft Entra ID tenant         ← your organisation's identity directory (users, groups, apps)
└── Management groups              ← folders for subscriptions; policies applied here inherit down
    └── Subscriptions              ← billing + access boundary
        └── Resource groups        ← a lifecycle container: things deployed & deleted together
            └── Resources          ← VM, storage account, function app, VNet…
```

- **Region**: a geographic location (e.g. `centralindia`, `westeurope`). Some regions are **paired** for DR.
- **Availability Zone (AZ)**: physically separate datacentres inside one region. Zone-redundant = survives a datacentre failure; multi-region = survives a region failure.
- **Azure Resource Manager (ARM)**: the API behind everything. The Portal, CLI, Terraform and Bicep all call ARM.

**Learn:** create a resource group in the Portal, then do the same with the CLI:
```bash
az login
az group create --name rg-test --location centralindia --tags owner=jaival
az group delete --name rg-test --yes
```

**On AWS and GCP:** AWS = Organization → OUs → **accounts** (the hard isolation boundary; there are no
resource groups, so you group with tags and stacks). GCP = Organization → folders → **projects**. Regions
and zones exist on all three clouds, with different names (`ap-south-1` / `centralindia` / `asia-south1`
are all Mumbai-area regions).

✅ *You're ready when* you can explain why you'd put two resources in the same resource group, or in
different ones, and what plays that role on AWS and GCP.

---

## 2. Identity & access (the most important cloud skill)

| Concept | Plain-English meaning |
|---|---|
| **Microsoft Entra ID** (formerly Azure AD) | The directory of identities |
| **Authentication** | *Who are you?* (sign-in, tokens) |
| **Authorization / RBAC** | *What may you do?* Role assignments = **who** + **role** + **scope** |
| **Built-in roles** | `Owner`, `Contributor`, `Reader`, plus specific ones like `Storage Blob Data Reader` |
| **Service principal / App registration** | An identity for an application (e.g. your CI pipeline) |
| **Managed identity** | An identity Azure creates *for a resource* — no password exists anywhere. Use it whenever one Azure resource talks to another. |
| **Least privilege** | Give the smallest role at the smallest scope that works |

Key insight you'll repeat in interviews: **"The best secret is one that doesn't exist."**
Managed identities (resource → resource) and OIDC federation (GitHub → Azure) remove secrets entirely.

**IAM is where the clouds differ most.** Learn all three models:
- **AWS**: permissions are **JSON policy documents** (`Effect`, `Action`, `Resource`, `Condition`). Workloads *assume* an **IAM role** and get temporary credentials from STS. An explicit `Deny` always wins.
  ```json
  { "Effect": "Allow", "Action": "s3:GetObject", "Resource": "arn:aws:s3:::my-bucket/*" }
  ```
- **Azure**: **role assignments** = principal + role definition + scope (management group → subscription → resource group → resource).
- **GCP**: **IAM bindings** = principal + role on a resource (organization → folder → project → resource). Workloads run as **service accounts**. Prefer predefined roles like `roles/storage.objectViewer` over the broad basic roles (`Owner`/`Editor`/`Viewer`).

✅ *You're ready when* you can explain the difference between `Contributor` on a subscription and
`Storage Blob Data Contributor` on one storage account, and write the equivalent read-only access for
one bucket as an AWS IAM policy and a GCP IAM binding.

---

## 3. Networking fundamentals

You'll use these in almost every project, especially 01, 02, 03 and 07.

- **IP addressing & CIDR**: `10.0.0.0/16` = 65,536 addresses; `/24` = 256. Learn to split a `/16` into `/24` subnets.
- **VNet**: your private network in Azure. **Subnet**: a slice of it.
- **NSG (Network Security Group)**: stateful firewall rules on a subnet/NIC (allow/deny by IP, port, protocol).
- **Public vs private IP**, **NAT Gateway** (controlled outbound internet).
- **VNet peering**: connect two VNets. **Hub-and-spoke**: shared services (firewall, VPN) in the hub, workloads in spokes.
- **Private Endpoint**: gives a PaaS service (Storage, SQL, Key Vault) a private IP inside your VNet so it's not reachable from the internet.
- **DNS**: how names become IPs; **Private DNS zones** make private endpoints resolvable.
- **Load balancers**: Layer 4 (Azure Load Balancer — TCP/UDP) vs Layer 7 (Application Gateway, Front Door — HTTP, paths, WAF).
- **TLS/HTTPS**: certificates, why port 443.

**On AWS and GCP:** AWS VPCs are regional and **each subnet lives in one AZ**, so you create one subnet
per AZ. A "public subnet" is simply one whose route table points to an **Internet Gateway**. Security
Groups (stateful) plus NACLs (stateless) replace NSGs. **GCP VPCs are global**: one VPC can have subnets
in every region, and firewall rules target **network tags or service accounts** instead of subnets.

✅ *You're ready when* you can draw a network with a public and a private subnet on each cloud and say
which traffic each firewall layer allows.

---

## 4. Linux & scripting

- Navigate the shell: `ls, cd, cat, grep, less, tail -f, ps, top, systemctl, journalctl, curl, ssh, chmod`
- Bash basics: variables, `if`, loops, exit codes, pipes.
- **Python** (preferred for Functions, scripts, project 10) *or* **PowerShell** (Azure Automation runbooks). Learn one well; read the other.
- JSON & YAML: you'll read/write them constantly. Learn `jq`.

✅ *You're ready when* you can write a script that calls `az` CLI, parses JSON output with `jq`, and loops over results.

---

## 5. Git & GitHub

- `clone, add, commit, push, pull, branch, merge, rebase`, resolving conflicts.
- Pull requests, branch protection, code review.
- `.gitignore` — **never commit** `*.tfstate`, `.terraform/`, `*.tfvars` with secrets, `.env`.
- Conventional commits (`feat:`, `fix:`, `docs:`) make history readable.

✅ *You're ready when* you work in feature branches and merge via PRs, even when solo.

---

## 6. Infrastructure as Code with Terraform

Every project uses IaC. Terraform is the most portable choice (works on AWS/GCP too, good for the CV).
Bicep is Azure-native and also good — pick Terraform as the main tool and try Bicep once in a project for comparison.

Core concepts:

| Concept | Meaning |
|---|---|
| **Provider** | Plugin that talks to an API (`azurerm`, `azuread`, `azapi`) |
| **Resource** | Something Terraform creates (`azurerm_resource_group`) |
| **Data source** | Something Terraform reads but doesn't own |
| **Variables / outputs / locals** | Inputs, results, and computed values |
| **State** | Terraform's record of what exists. Store it **remotely** (Azure Storage blob) with locking — never in Git |
| **Plan / apply / destroy** | Preview, change, tear down |
| **Modules** | Reusable bundles (e.g. a `network` module used by several projects) |
| **Drift** | When reality differs from code (someone clicked in the Portal) |

Minimal example:
```hcl
terraform {
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 4.0" }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-demo"
  location = "centralindia"
  tags     = { owner = "jaival", project = "00" }
}
```
```bash
terraform init && terraform plan && terraform apply
terraform destroy
```

Also learn: `terraform fmt`, `terraform validate`, `tflint`, and a security scanner (`checkov` or `trivy config`).

**Multi-cloud Terraform:**
- **Remote state backends**: `s3` (native locking with `use_lockfile = true`), `azurerm` (blob lease), `gcs` (built-in locking). Keep **one state per project per cloud** — never put three clouds in one state file, or one cloud's outage blocks changes to the others.
- **Same interface, different implementation**: every `infra/<cloud>/` folder takes the same variables (`project`, `env`, `region`, `tags`) and returns the same outputs (`app_url`, `log_query_link`…). The pipeline doesn't need to know which cloud it's deploying.
- Tags in Azure/AWS vs **labels** in GCP (lowercase letters, numbers, `_` and `-` only).

✅ *You're ready when* you can deploy a bucket/storage account with remote state on each of the three
clouds, then destroy it.

---

## 7. CI/CD with GitHub Actions

- **Workflow** (`.github/workflows/*.yml`) → **jobs** → **steps**. Triggers: `push`, `pull_request`, `workflow_dispatch`, `schedule`.
- **Environments** with required reviewers (manual approval before prod).
- Typical IaC pipeline: `fmt → validate → lint/scan → plan (on PR, post as comment) → apply (on merge to main)`.
- Project 09 teaches the secure authentication part.

✅ *You're ready when* you have a workflow that runs `terraform fmt -check` on every PR.

---

## 8. Containers (needed for 01, 02, 07)

- Image vs container, `Dockerfile`, layers, `docker build/run/push`.
- Registries: **Azure Container Registry (ACR)**, GitHub Container Registry.
- Why containers: same artifact runs everywhere.

✅ *You're ready when* you can containerise a tiny Python/Node web app and run it locally.

---

## 9. Observability basics

- **Metrics** (numbers over time: CPU, request rate), **logs** (events), **traces** (a request's journey across services).
- **Azure Monitor** = the umbrella. **Log Analytics workspace** = where logs live. **Application Insights** = app telemetry (APM).
- **KQL (Kusto Query Language)** is used in projects 01, 02, 06, 08 and 10. Start now:
  ```kusto
  AppRequests
  | where TimeGenerated > ago(1h)
  | summarize count(), avg(DurationMs) by bin(TimeGenerated, 5m), ResultCode
  | render timechart
  ```
- **Alerts** → **Action groups** (email, SMS, webhook, Function, Logic App, Automation runbook).

The same question on the other clouds:
- **AWS CloudWatch Logs Insights**:
  ```
  fields @timestamp, status
  | filter status >= 500
  | stats count(*) by bin(5m)
  ```
- **GCP Cloud Logging** filter (`httpRequest.status>=500`), or **SQL** over logs with Log Analytics / BigQuery:
  ```sql
  SELECT TIMESTAMP_TRUNC(timestamp, MINUTE) AS minute, COUNT(*) AS errors
  FROM `my-project.global._Default._AllLogs`
  WHERE http_request.status >= 500
  GROUP BY minute ORDER BY minute
  ```
- **OpenTelemetry** lets one instrumented app send traces/metrics to any of the three. Use it so your app code doesn't change between clouds.

✅ *You're ready when* you can count failed requests per 5 minutes on each cloud's log tool.

---

## 10. Recommended learning resources (free)

- **Microsoft Learn** — learning paths for AZ-900 / AZ-104 (free, with sandboxes)
- **AWS Skill Builder** — free courses for Cloud Practitioner / Solutions Architect Associate
- **Google Cloud Skills Boost** — labs and learning paths for Associate Cloud Engineer
- **Architecture centres**: Azure Architecture Center, AWS Architecture Center, Google Cloud Architecture Center — reference architectures for diagrams and "why" decisions
- **Well-Architected Frameworks** — all three clouds publish one. Microsoft and Google use 5 pillars; AWS has 6 (adds **sustainability**). The vocabulary interviewers love: reliability, security, cost optimisation, operational excellence, performance efficiency
- **HashiCorp Developer** — Terraform tutorials (Azure track)
- **KQL**: the "Must Learn KQL" series and the Log Analytics demo workspace
- **Kubernetes**: the official docs' tutorials, then KodeKloud/Killercoda labs
