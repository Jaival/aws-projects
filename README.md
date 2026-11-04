# ☁️ Multi-Cloud Engineering Projects — AWS · Azure · GCP

Ten hands-on cloud engineering projects, each **designed once and built on all three major clouds**
with **Terraform**, deployed through **GitHub Actions with OIDC (no stored secrets)**, documented with
architecture diagrams and a cross-cloud comparison, and torn down after the demo.

> 📍 Start with the **[ROADMAP](ROADMAP.md)** (strategy, build order, timeline, definition of done), then
> **[Foundations](docs/00-foundations.md)**, the **[multi-cloud service map](docs/multi-cloud-service-map.md)**,
> and the **[Phase 0 exercises](foundations/)**.

![terraform-checks](https://github.com/Jaival/aws-projects/actions/workflows/terraform-checks.yml/badge.svg)

## Projects

| # | Project | AWS | Azure | GCP | Build order |
|---|---|---|---|---|---|
| 01 | [Self-Healing Web App](projects/01-self-healing-web-app/) | ECS Fargate, ALB, CloudWatch | App Service, App Insights | Cloud Run, Cloud Monitoring | 3 |
| 02 | [Multi-Region Disaster Recovery](projects/02-multi-region-dr/) | Route 53, Aurora Global DB | Front Door, SQL failover groups | Global LB, Cloud SQL replicas | 7 |
| 03 | [Zero-Trust Landing Zone](projects/03-zero-trust-landing-zone/) | Control Tower, SCPs, Transit Gateway | Management groups, Azure Policy, Firewall | Org Policy, Shared VPC, VPC-SC | 4 |
| 04 | [Serverless Event-Driven Order Pipeline](projects/04-serverless-order-pipeline/) | Lambda, SQS, Step Functions, DynamoDB | Functions, Service Bus, Durable Functions, Cosmos DB | Cloud Run functions, Pub/Sub, Workflows, Firestore | 5 |
| 05 | [Cloud Cost Watchdog with Auto-Shutdown](projects/05-cost-watchdog/) | Budgets, Cost Explorer, Lambda | Cost Management, Resource Graph, Functions | Billing budgets, BigQuery export | 2 |
| 06 | [Cloud Threat Detection (SIEM)](projects/06-cloud-threat-detection/) | CloudTrail, GuardDuty, Security Hub | Sentinel, Defender for Cloud | Audit Logs, Security Command Center | 9 |
| 07 | [GitOps Kubernetes Platform with ArgoCD](projects/07-gitops-kubernetes-argocd/) | EKS, Karpenter, ECR | AKS, ACR | GKE, Artifact Registry | 8 |
| 08 | [Real-Time IoT Telemetry Pipeline](projects/08-iot-telemetry-pipeline/) | IoT Core, Kinesis, Flink | IoT Hub, Event Hubs, Stream Analytics, ADX | MQTT broker, Pub/Sub, Dataflow, BigQuery | 6 |
| 09 | [Secrets-Free CI/CD with GitHub OIDC](projects/09-secrets-free-cicd-oidc/) | IAM OIDC provider + role | Entra federated credential | Workload Identity Federation | 1 |
| 10 | [AI-Powered Log Analyzer](projects/10-ai-log-analyzer/) | Bedrock | Azure OpenAI (AI Foundry) | Vertex AI | 10 |

### Progress

| # | Design | Azure | AWS | GCP | Comparison |
|---|---|---|---|---|---|
| 01 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| 02 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| 03 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| 04 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| 05 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| 06 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| 07 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| 08 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| 09 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| 10 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |

## Skills matrix

Which skills each project exercises (● = core, ○ = supporting):

| Skill | 01 | 02 | 03 | 04 | 05 | 06 | 07 | 08 | 09 | 10 |
|---|---|---|---|---|---|---|---|---|---|---|
| Terraform / IaC (3 providers) | ● | ● | ● | ● | ○ | ○ | ● | ○ | ● | ○ |
| GitHub Actions CI/CD | ○ | ● | ○ | ○ | ○ | ○ | ● | ○ | ● | ○ |
| IAM on AWS / Azure / GCP | ○ | ○ | ● | ○ | ● | ○ | ● | ○ | ● | ● |
| Networking (VPC/VNet, DNS, private access) | ○ | ● | ● | ○ |   | ○ | ● | ○ |   | ○ |
| Monitoring & log queries (KQL, Logs Insights, SQL) | ● | ● | ○ | ○ | ○ | ● | ○ | ● |   | ● |
| Containers / Kubernetes | ● | ○ |   |   |   |   | ● | ○ |   |   |
| Serverless functions | ○ |   |   | ● | ● | ○ |   | ○ |   | ● |
| Messaging & streaming |   |   |   | ● |   |   |   | ● |   |   |
| Databases & storage | ○ | ● | ○ | ● |   |   |   | ● | ○ | ○ |
| Security & governance | ○ | ○ | ● | ○ | ○ | ● | ● | ○ | ● | ○ |
| Reliability / DR | ● | ● |   | ○ |   |   | ○ |   |   |   |
| Cost management (FinOps) | ○ | ○ | ○ |   | ● | ○ | ○ | ○ |   | ○ |
| Portable design (adapters, OpenTelemetry) | ● | ○ |   | ● | ○ |   | ● | ● | ○ | ● |
| Python scripting | ○ | ○ |   | ● | ● | ○ |   | ● |   | ● |
| AI / LLMs |   |   |   |   |   |   |   |   |   | ● |

## Repository layout

```
.
├── ROADMAP.md                      # strategy, build order, phases, definition of done, cost rules
├── docs/
│   ├── 00-foundations.md           # what to learn before project 1 (all three clouds)
│   ├── multi-cloud-service-map.md  # AWS ↔ Azure ↔ GCP equivalents and key differences
│   ├── diagrams.md                 # how to make the architecture diagrams
│   └── interview-guide.md          # how to present each project
├── foundations/                    # Phase 0 hands-on: hello-storage + remote state on each cloud
├── scripts/check-tools.sh          # are the CLIs installed and logged in?
├── modules/                        # shared Terraform modules, per cloud
│   ├── aws/  ├── azure/  └── gcp/
├── .github/workflows/              # reusable multi-cloud Terraform workflow (project 09)
└── projects/
    └── NN-project-name/
        ├── README.md               # learning guide → becomes the project write-up
        ├── docs/                   # diagrams (neutral + per cloud), comparison.md, notes, runbooks
        ├── src/                    # app code, shared across clouds; cloud specifics in adapters/
        └── infra/
            ├── aws/                # same variables & outputs on every cloud
            ├── azure/
            └── gcp/
```

## Conventions
- **Regions** (Mumbai area by default — change in each `variables.tf`):

  | | AWS | Azure | GCP |
  |---|---|---|---|
  | Primary | `ap-south-1` | `centralindia` | `asia-south1` |
  | Secondary (DR) | `ap-south-2` | `southindia` | `asia-south2` |

- **Naming**: `<type>-<project>-<env>-<region-short>`, e.g. `rg-p01-dev-cin`, `p01-dev-aps1-alb`. Follow each cloud's naming rules (S3/GCS buckets are globally unique; Azure storage accounts allow no dashes).
- **Tags / labels** on everything, **lowercase** so the same keys work on GCP: `project`, `owner`, `env`, `autoshutdown`.
- **No secrets in Git**, ever. CI uses OIDC on all three clouds; workloads use IAM roles, managed identities or service accounts.
