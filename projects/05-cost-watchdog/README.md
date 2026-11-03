# 05 · Cloud Cost Watchdog with Auto-Shutdown

> **Build order: #2** · Difficulty ⭐⭐ · lead cloud ~1–2 weeks · Azure cost: ≈ $0–5/month

## The problem
Cloud bills grow quietly: a forgotten VM over the weekend, a dev AKS cluster left running, a resource
nobody owns. Budgets alone only *notify* — they don't *act*.

## What you'll build
A watchdog that (a) alerts as spend approaches budget, (b) automatically stops/deallocates tagged
non-production resources when a threshold is crossed or outside working hours, (c) finds untagged and
orphaned resources, and (d) sends a weekly cost report. Build it early — it protects your wallet for
the other 8 projects.

```mermaid
flowchart LR
    B[Azure Budget<br/>50% / 80% / 100%] -->|threshold crossed| AG[Action Group]
    AG -->|email| You[You]
    AG -->|webhook| F[Azure Function<br/>Python, managed identity]
    T[Timer trigger<br/>19:00 weekdays] --> F
    F -->|Resource Graph query:<br/>tag autoshutdown=true| RG[Azure Resource Graph]
    F -->|deallocate VMs / stop AKS /<br/>stop App Service / scale to 0| R[Tagged resources]
    W[Weekly timer] --> CR[Function: cost report]
    CR -->|Cost Management Query API| CM[Cost Management]
    CR -->|summary| Teams[Email / Teams / Slack]
    F --> LA[Log Analytics<br/>audit of every action]
```

## Multi-cloud implementation

The diagram above is the **Azure reference implementation** (Azure is the lead cloud — see the [roadmap](../../ROADMAP.md#1-the-strategy-design-once-build-three-times)). Build it there first, then port it using the mapping below. Full service list: [multi-cloud service map](../../docs/multi-cloud-service-map.md).

| Component | AWS | Azure | GCP |
|---|---|---|---|
| Budget + alerts | **AWS Budgets** → SNS / email | Cost Management budget → Action Group | **Cloud Billing budget** → email + **Pub/Sub** topic |
| Built-in automatic action | **Budget Actions** can apply an IAM/SCP policy or stop EC2/RDS instances | — (use Action Group → Function) | — (Pub/Sub → function) |
| Find tagged resources | Resource Groups Tagging API / AWS Config / Resource Explorer | Resource Graph | **Cloud Asset Inventory** |
| Scheduler | EventBridge Scheduler | Function timer trigger | Cloud Scheduler |
| Automation code | Lambda (Python, `boto3`) | Functions (Python, `azure-mgmt-*`) | Cloud Run functions (Python, `google-cloud-*`) |
| Stop actions | Stop EC2, ECS desired count → 0, **RDS stop**, EKS node group → 0 | Deallocate VMs, stop App Service, `az aks stop` | Stop Compute Engine VMs, GKE node pool → 0, Cloud SQL activation policy `NEVER` |
| Cost data API | Cost Explorer API / CUR 2.0 data exports | Cost Management Query API / exports | **BigQuery billing export** (query with SQL) |
| Anomaly detection | Cost Anomaly Detection | Cost anomaly alerts | Cost anomaly detection |
| Tag/label policy | Tag policies (Organizations) + SCP | Azure Policy | Organization Policy / label checks in CI |

**Differences that matter**
- **AWS:** tags only appear in billing after you **activate them as cost allocation tags**. A stopped RDS instance **restarts automatically after 7 days** — your watchdog has to handle that. The Cost Explorer API charges per request, so cache results.
- **GCP:** **labels** must be lowercase. Budgets **don't stop anything** on their own; Google's own "cap spending" example *disables billing on the project*, which can delete resources. Explain why you chose to stop resources instead. Cloud Run already scales to zero, so there's less to stop.
- **Azure:** `deallocate`, not `stop`, is what stops compute billing for VMs.

**Truly multi-cloud version:** one weekly report combining spend from all three bills, using one
lowercase tagging standard (`project`, `owner`, `env`, `autoshutdown`). Optionally load all three billing
exports into one place (e.g. BigQuery or DuckDB) and normalise them with the **FOCUS** open billing format,
which all three clouds now support.

## Skills & concepts you'll learn

### FinOps fundamentals
- **FinOps** = making engineering teams accountable for cloud spend. Phases: *Inform → Optimise → Operate*.
- **Cost allocation with tags** (`owner`, `project`, `env`, `costcenter`). Untagged = unaccountable.
- Common waste: idle compute, oversized SKUs, unattached disks, unused public IPs, old snapshots, non-prod running 24/7 (168 h/week vs ~50 working hours ≈ 70% saving).
- Reserved instances / savings plans vs pay-as-you-go vs spot VMs — know when each fits.

### Azure Cost Management + Budgets
- Budgets at subscription or resource-group scope, with **actual** and **forecasted** thresholds.
- Budgets → **Action Groups** → email / webhook / Function / Logic App / Automation runbook.
- **Cost Management Query API** for programmatic reports; **cost exports** to a storage account for history.
- Note: cost data has a delay (hours, not seconds) — the watchdog is a guardrail, not a hard cap.

### Azure Resource Graph
- Query *every* resource across subscriptions in seconds with KQL:
  ```kusto
  Resources
  | where type =~ 'microsoft.compute/virtualmachines'
  | where tags['autoshutdown'] =~ 'true'
  | project name, resourceGroup, location, tags
  ```
- Find orphans: disks where `managedBy` is empty, public IPs with no `ipConfiguration`.

### Azure Functions (your first serverless code)
- Triggers (timer, HTTP) and bindings; the **Flex Consumption** plan (scale to zero, pay per execution).
- CRON expressions for timer triggers (`0 0 19 * * 1-5` = 19:00 Mon–Fri; Functions use 6 fields incl. seconds).
- Using the Azure SDK for Python (`azure-identity`, `azure-mgmt-compute`, `azure-mgmt-resourcegraph`) with `DefaultAzureCredential` → **managed identity** in Azure, your `az login` locally.
- Custom RBAC role: only `Microsoft.Compute/virtualMachines/deallocate/action`, `.../start/action`, `read` — least privilege in practice.

### Azure Policy (light introduction — goes deep in project 03)
- Policy to **require** the `owner` and `env` tags, or **inherit** tags from the resource group.
- Effects: `audit`, `deny`, `modify`.

### Alternatives worth knowing (and why you chose Functions)
- **Azure Automation** runbooks (PowerShell) + Start/Stop VMs v2 — older, but common in enterprises.
- **Logic Apps** — low-code, good for notifications.
- Being able to say *why* you picked one is the interview value.

## Build plan
1. Tag strategy doc + Azure Policy requiring tags.
2. Budget (Terraform `azurerm_consumption_budget_subscription`) with 50/80/100% + forecast alert → Action Group (email).
3. Function app with managed identity + custom role. Timer function: Resource Graph query → deallocate tagged VMs / stop App Services / stop AKS.
4. Webhook function triggered by the 100% budget alert → emergency stop of all `env=dev` resources.
5. "Opt-out" tag: `autoshutdown=false` or `keepalive-until=2026-12-01`.
6. Weekly report function: spend by `project` tag, top 5 costs, orphaned resources → email/Teams.
7. Log every action to Log Analytics; build a workbook showing "hours saved / estimated $ saved".

## Cost hot-spots
Nearly free. Function executions fall within free grants; Log Analytics ingestion is tiny.

## Stretch goals
- Auto-**start** at 08:00 for resources tagged `schedule=office-hours`.
- Anomaly detection: compare today's spend with the 7-day average and alert on > 2× spikes.
- Rightsizing suggestions from **Azure Advisor** API included in the weekly report.
- Slack/Teams interactive button: "Keep running for 4 more hours".

## Interview talking points
- Quantify: "Dev resources now run ~50 h/week instead of 168 h — about 70% compute saving."
- Safety: least-privilege custom role, opt-out tags, audit trail of every shutdown.
- Limitations: cost data latency → budgets aren't a hard cap; that's why the schedule-based shutdown exists too.
