# 00 · Foundations — what to know before project 1

You don't need to master all of this first. Learn it well enough to follow along, then deepen it
while building. Each section ends with a **"you're ready when…"** check.

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

✅ *You're ready when* you can explain why you'd put two resources in the same resource group, or in different ones.

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

✅ *You're ready when* you can explain the difference between `Contributor` on a subscription and `Storage Blob Data Contributor` on one storage account.

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

✅ *You're ready when* you can draw a VNet with a public subnet and a private subnet and say which traffic each NSG allows.

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

✅ *You're ready when* you can deploy a resource group + storage account with remote state, then destroy it.

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

✅ *You're ready when* you can write a KQL query that counts failed requests per 5 minutes.

---

## 10. Recommended learning resources (free)

- **Microsoft Learn** — learning paths for AZ-900 / AZ-104 (free, with sandboxes)
- **Azure Architecture Center** — reference architectures (great for diagrams and "why" decisions)
- **Cloud Adoption Framework** & **Well-Architected Framework** — vocabulary interviewers love: reliability, security, cost optimisation, operational excellence, performance efficiency
- **HashiCorp Developer** — Terraform tutorials (Azure track)
- **KQL**: the "Must Learn KQL" series and the Log Analytics demo workspace
- **Kubernetes**: the official docs' tutorials, then KodeKloud/Killercoda labs
