# ☁️ Azure Cloud Projects

Ten hands-on Azure cloud engineering projects. Each one is built with **Terraform**, deployed through
**GitHub Actions with OIDC (no stored secrets)**, documented with an **architecture diagram**, and
torn down after the demo.

> 📍 Start with the **[ROADMAP](ROADMAP.md)** (build order, timeline, definition of done), then
> **[Foundations](docs/00-foundations.md)**.

## Projects

| # | Project | Key Azure services | Build order | Status |
|---|---|---|---|---|
| 01 | [Self-Healing Web App](projects/01-self-healing-web-app/) | App Service, App Insights, Azure Monitor, Functions | 3 | ⬜ Not started |
| 02 | [Multi-Region Disaster Recovery Failover](projects/02-multi-region-dr/) | Front Door, SQL Failover Groups, GZRS, Chaos Studio | 7 | ⬜ Not started |
| 03 | [Zero-Trust Landing Zone](projects/03-zero-trust-landing-zone/) | Management Groups, Azure Policy, Firewall, Private Endpoints | 4 | ⬜ Not started |
| 04 | [Serverless Event-Driven Order Pipeline](projects/04-serverless-order-pipeline/) | Functions, Durable Functions, Service Bus, Event Grid, Cosmos DB, APIM | 5 | ⬜ Not started |
| 05 | [Cloud Cost Watchdog with Auto-Shutdown](projects/05-cost-watchdog/) | Cost Management, Budgets, Resource Graph, Functions | 2 | ⬜ Not started |
| 06 | [Threat Detection with Microsoft Sentinel](projects/06-sentinel-threat-detection/) | Sentinel, Log Analytics, KQL, Logic Apps | 9 | ⬜ Not started |
| 07 | [GitOps AKS Platform with ArgoCD](projects/07-gitops-aks-argocd/) | AKS, ACR, ArgoCD, Helm, Workload Identity | 8 | ⬜ Not started |
| 08 | [Real-Time IoT Telemetry Pipeline](projects/08-iot-telemetry-pipeline/) | IoT Hub, Event Hubs, Stream Analytics, Data Explorer | 6 | ⬜ Not started |
| 09 | [Secrets-Free CI/CD with GitHub OIDC](projects/09-secrets-free-cicd-oidc/) | Entra ID workload identity federation, GitHub Actions | 1 | ⬜ Not started |
| 10 | [AI-Powered Log Analyzer](projects/10-ai-log-analyzer/) | Azure OpenAI, AI Search, Log Analytics, Functions | 10 | ⬜ Not started |

## Skills matrix

Which skills each project exercises (● = core, ○ = supporting):

| Skill | 01 | 02 | 03 | 04 | 05 | 06 | 07 | 08 | 09 | 10 |
|---|---|---|---|---|---|---|---|---|---|---|
| Terraform / IaC | ● | ● | ● | ● | ○ | ○ | ● | ○ | ● | ○ |
| GitHub Actions CI/CD | ○ | ● | ○ | ○ | ○ | ○ | ● | ○ | ● | ○ |
| Identity, RBAC, managed identity | ○ | ○ | ● | ○ | ● | ○ | ● | ○ | ● | ● |
| Networking (VNet, DNS, private endpoints) | ○ | ● | ● | ○ |   | ○ | ● | ○ |   | ○ |
| Monitoring, KQL, alerting | ● | ● | ○ | ○ | ○ | ● | ○ | ● |   | ● |
| Containers / Kubernetes | ● | ○ |   |   |   |   | ● | ○ |   |   |
| Serverless (Functions) | ○ |   |   | ● | ● | ○ |   | ○ |   | ● |
| Messaging & streaming |   |   |   | ● |   |   |   | ● |   |   |
| Databases & storage | ○ | ● | ○ | ● |   |   |   | ● | ○ | ○ |
| Security & governance | ○ | ○ | ● | ○ | ○ | ● | ● | ○ | ● | ○ |
| Reliability / DR | ● | ● |   | ○ |   |   | ○ |   |   |   |
| Cost management (FinOps) | ○ | ○ | ○ |   | ● | ○ | ○ | ○ |   | ○ |
| Python scripting | ○ | ○ |   | ● | ● | ○ |   | ● |   | ● |
| AI / LLMs |   |   |   |   |   |   |   |   |   | ● |

## Repository layout

```
.
├── ROADMAP.md                  # build order, phases, definition of done, cost rules
├── docs/
│   ├── 00-foundations.md       # what to learn before project 1
│   ├── diagrams.md             # how to make the architecture diagrams
│   └── interview-guide.md      # how to present each project
├── modules/                    # shared Terraform modules (network, monitoring, …)
├── .github/workflows/          # CI/CD pipelines (reusable Terraform workflow from project 09)
└── projects/
    └── NN-project-name/
        ├── README.md           # learning guide → becomes the project write-up
        ├── docs/               # architecture diagram, notes, runbooks
        ├── infra/              # Terraform
        └── src/                # application / function code
```

## Conventions
- **Region**: `centralindia` (secondary `southindia`) — change in each project's `variables.tf`.
- **Naming**: `<type>-<project>-<env>-<region>`, e.g. `rg-p01-dev-cin`, following the Azure CAF abbreviations.
- **Tags** on everything: `project`, `owner`, `env`, `autoshutdown`.
- **No secrets in Git**, ever. Identities are federated (OIDC) or managed.
