# Multi-cloud service map — AWS · Azure · GCP

Learn the **concept** first, then the three product names. Names change; concepts don't.

> Services get renamed or retired every year (GCP IoT Core is gone, AWS has closed some services to new
> customers). Check each service's current status in the official docs before you start a project.

---

## 1. Concepts that work differently on each cloud

Read this before anything else. These differences cause most multi-cloud bugs.

### Resource hierarchy
| | AWS | Azure | GCP |
|---|---|---|---|
| Top level | **Organization** (management account) | **Entra ID tenant** | **Organization** (tied to a Google Workspace / Cloud Identity domain) |
| Grouping | **Organizational Units (OUs)** | **Management groups** | **Folders** |
| Isolation / billing unit | **Account** | **Subscription** | **Project** |
| Lifecycle grouping | Tags / CloudFormation stacks (no direct equivalent) | **Resource group** | (project is the main grouping) |
| Guardrails | **Service Control Policies (SCPs)**, AWS Config rules | **Azure Policy** | **Organization Policy** constraints |

Key point: on AWS the **account** is the hard isolation boundary, so landing zones use *many accounts*.
Azure uses subscriptions + resource groups; GCP uses *many projects*.

### Identity & access (IAM)
| | AWS | Azure | GCP |
|---|---|---|---|
| Human identities | IAM Identity Center (SSO) | Entra ID users/groups | Cloud Identity / Google Workspace |
| Permission model | **JSON policies** (allow/deny on actions + resources + conditions) attached to users/roles; **roles** are *assumed* | **RBAC role assignments**: principal + role + scope | **IAM bindings**: principal + role on a resource (inherits down org → folder → project) |
| Identity for workloads | **IAM role** (EC2 instance profile, Lambda execution role, EKS Pod Identity / IRSA) | **Managed identity** | **Service account** (GKE Workload Identity Federation) |
| CI/CD without secrets | IAM **OIDC identity provider** + role trust policy → `sts:AssumeRoleWithWebIdentity` | Entra **federated identity credential** | **Workload Identity Federation** pool + provider |
| Explicit deny? | Yes — deny always wins | Deny assignments (limited) | IAM deny policies |

### Networking
| | AWS | Azure | GCP |
|---|---|---|---|
| Private network | **VPC** — *regional* | **VNet** — *regional* | **VPC** — ***global***, subnets are regional |
| Subnets | Tied to one **Availability Zone** | Span all zones in the region | Span all zones in the region |
| Firewalling | **Security Groups** (stateful, per ENI) + NACLs (stateless, per subnet) | **NSGs** (+ ASGs) | **VPC firewall rules / policies** (by network tags or service accounts) |
| Hub-and-spoke | **Transit Gateway** | VNet peering via hub / Virtual WAN | **Shared VPC**, VPC peering, Network Connectivity Center |
| Private access to managed services | **VPC endpoints** (Gateway / Interface — PrivateLink) | **Private Endpoint** (Private Link) | **Private Service Connect**, Private Google Access |
| Outbound NAT | NAT Gateway | NAT Gateway | Cloud NAT |
| Managed firewall | AWS Network Firewall | Azure Firewall | Cloud Next Generation Firewall (Cloud NGFW) |
| Admin access without public IPs | **SSM Session Manager** | **Azure Bastion** | **IAP TCP forwarding** |
| DNS | Route 53 (+ private hosted zones) | Azure DNS / Private DNS zones | Cloud DNS (private zones) |

Biggest surprise: a GCP VPC spans every region, so a multi-region GCP design often needs *one* network,
while AWS and Azure need one per region plus peering.

### Infrastructure as code
| Tool | Works on |
|---|---|
| **Terraform / OpenTofu** ← main tool in this repo | All three (`aws`, `azurerm`, `google` providers) |
| Pulumi | All three (real programming languages) |
| CloudFormation / CDK | AWS only |
| Bicep / ARM | Azure only |
| Infrastructure Manager (managed Terraform) | GCP |

Terraform doesn't make code portable: an `aws_lambda_function` and an `azurerm_linux_function_app` are
completely different resources. What carries over is the **workflow, the module structure and the
interface** (same input variables and outputs for every cloud).

---

## 2. Service equivalents by category

### Compute
| Purpose | AWS | Azure | GCP |
|---|---|---|---|
| Virtual machines | EC2 | Virtual Machines | Compute Engine |
| Auto-scaled VM group with auto-repair | Auto Scaling Group (+ ELB health checks) | VM Scale Sets (automatic instance repairs) | Managed Instance Group (autohealing) |
| Managed containers, no cluster | ECS on Fargate | Container Apps / App Service | **Cloud Run** |
| Managed Kubernetes | EKS | AKS | GKE (Standard / Autopilot) |
| Functions | Lambda | Azure Functions | Cloud Run functions |
| Workflow / orchestration | Step Functions | Durable Functions / Logic Apps | Workflows |
| Container registry | ECR | ACR | Artifact Registry |

### Data
| Purpose | AWS | Azure | GCP |
|---|---|---|---|
| Object storage | S3 | Blob Storage / ADLS Gen2 | Cloud Storage |
| Managed relational | RDS / Aurora | Azure SQL / Database for PostgreSQL | Cloud SQL / AlloyDB |
| Globally distributed relational | Aurora Global Database / Aurora DSQL | Azure SQL geo-replication | Spanner |
| NoSQL document/key-value | DynamoDB | Cosmos DB | Firestore / Bigtable |
| Data warehouse | Redshift | Synapse / Microsoft Fabric | BigQuery |
| Query files in a lake | Athena | Synapse serverless / Fabric | BigQuery external tables |
| Log / time-series analytics | OpenSearch / CloudWatch Logs Insights | Azure Data Explorer / Fabric Eventhouse | BigQuery |

### Messaging & streaming
| Purpose | AWS | Azure | GCP |
|---|---|---|---|
| Queue | SQS | Service Bus queues / Storage queues | Pub/Sub (pull subscription) / Cloud Tasks |
| Pub/sub topics | SNS | Service Bus topics | Pub/Sub |
| Event routing | EventBridge | Event Grid | Eventarc |
| Streaming log | Kinesis Data Streams / MSK (Kafka) | Event Hubs | Pub/Sub / Managed Service for Apache Kafka |
| Stream processing | Managed Service for Apache Flink | Stream Analytics | Dataflow (Apache Beam) |
| IoT device gateway | AWS IoT Core | IoT Hub | *No native service* (IoT Core retired 2023) → MQTT broker on GKE/VM or a partner + Pub/Sub |

### Networking edge
| Purpose | AWS | Azure | GCP |
|---|---|---|---|
| L7 load balancer | Application Load Balancer | Application Gateway | Application Load Balancer (regional/global) |
| Global entry + CDN | CloudFront (+ Global Accelerator) | Front Door | Global external ALB + Cloud CDN |
| DNS failover | Route 53 health checks + failover routing | Traffic Manager | Cloud DNS routing policies |
| WAF | AWS WAF | Front Door / App Gateway WAF | Cloud Armor |
| API gateway | API Gateway | API Management | API Gateway / Apigee |

### Operations
| Purpose | AWS | Azure | GCP |
|---|---|---|---|
| Metrics + alarms | CloudWatch | Azure Monitor | Cloud Monitoring |
| Logs + query language | CloudWatch Logs (Logs Insights QL) | Log Analytics (**KQL**) | Cloud Logging (Logging query language; **SQL** via Log Analytics) |
| Tracing / APM | X-Ray / CloudWatch Application Signals | Application Insights | Cloud Trace |
| Synthetic checks | CloudWatch Synthetics | App Insights availability tests | Uptime checks |
| Alert → automation | Alarm → SNS/EventBridge → Lambda or SSM Automation | Alert → Action Group → Function/Runbook | Alerting policy → Pub/Sub → Cloud Run function |
| Scheduled jobs | EventBridge Scheduler | Function timer trigger / Logic Apps | Cloud Scheduler |
| Fault injection | Fault Injection Service (FIS) | Chaos Studio | *No native* → Chaos Mesh / LitmusChaos |
| Audit log | CloudTrail | Activity Log | Cloud Audit Logs |
| Resource inventory | AWS Config / Resource Explorer | Resource Graph | Cloud Asset Inventory |

### Security
| Purpose | AWS | Azure | GCP |
|---|---|---|---|
| Secrets | Secrets Manager / SSM Parameter Store | Key Vault | Secret Manager |
| Keys / encryption | KMS | Key Vault (keys) / Managed HSM | Cloud KMS |
| Threat detection | GuardDuty | Defender for Cloud | Security Command Center |
| Security posture | Security Hub | Defender for Cloud (CSPM) | Security Command Center |
| SIEM | Security Lake + OpenSearch (or 3rd-party SIEM) | **Microsoft Sentinel** | **Google Security Operations** (Chronicle) |
| SOAR / automated response | EventBridge + Lambda / Step Functions | Logic Apps playbooks | SecOps SOAR / Cloud Run functions |

### Cost
| Purpose | AWS | Azure | GCP |
|---|---|---|---|
| Budgets + alerts | AWS Budgets (+ Budget Actions) | Cost Management budgets | Cloud Billing budgets (→ Pub/Sub) |
| Cost analysis | Cost Explorer / CUR 2.0 / Data Exports | Cost Management + exports | Billing reports / **BigQuery billing export** |
| Recommendations | Compute Optimizer / Trusted Advisor | Azure Advisor | Recommender |
| Anomaly detection | Cost Anomaly Detection | Cost anomaly alerts | Cost anomaly detection |

### AI
| Purpose | AWS | Azure | GCP |
|---|---|---|---|
| Hosted LLMs | **Amazon Bedrock** (Claude, Llama, Nova…) | **Azure OpenAI** in Azure AI Foundry (also hosts other models, e.g. Claude) | **Vertex AI** (Gemini, Claude, Llama…) |
| Managed RAG | Bedrock Knowledge Bases | Azure AI Search ("On your data") | Vertex AI RAG Engine / Vertex AI Search |
| Vector store | OpenSearch Serverless / Aurora pgvector / S3 Vectors | Azure AI Search / Cosmos DB / PostgreSQL pgvector | Vertex AI Vector Search / AlloyDB / Cloud SQL pgvector |

---

## 3. Cloud-neutral tools used across this repo

Use these wherever you can. They're the same on every cloud, so you learn them once.

| Layer | Tool |
|---|---|
| IaC | Terraform |
| CI/CD | GitHub Actions + OIDC |
| Packaging | Docker, Helm, Kustomize |
| Kubernetes delivery | ArgoCD |
| Telemetry | **OpenTelemetry** (SDKs + Collector can export to all three clouds) |
| Dashboards | Grafana |
| Load testing | k6 |
| Policy as code | OPA / Conftest, Checkov, Kyverno |
| Chaos | Chaos Mesh / LitmusChaos |
| Messaging (portable) | Kafka, NATS, MQTT (EMQX / Mosquitto) |
| App code | Python (one language, three cloud SDKs: `boto3`, `azure-*`, `google-cloud-*`) |
