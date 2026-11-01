# Roadmap — 10 Azure Cloud Projects

> Goal: build 10 portfolio-grade Azure projects, each with Infrastructure-as-Code, CI/CD, an
> architecture diagram, and a write-up you can talk through in an interview.

---

## 1. Build order (not the same as the list order)

The projects are **numbered** 01–10 in the order from the original list (so folder names stay stable),
but you should **build** them in the order below. Each project reuses what the previous ones taught you.

| Step | Project | Why here | Est. time* | Difficulty |
|---|---|---|---|---|
| 0 | [Foundations](docs/00-foundations.md) | Azure, Linux, networking, Git, Terraform basics | 2–3 wks | ⭐ |
| 1 | [09 · Secrets-Free CI/CD with GitHub OIDC](projects/09-secrets-free-cicd-oidc/) | Every later project deploys through this pipeline | 1 wk | ⭐⭐ |
| 2 | [05 · Cloud Cost Watchdog](projects/05-cost-watchdog/) | Protects your wallet for all remaining projects | 1–2 wks | ⭐⭐ |
| 3 | [01 · Self-Healing Web App](projects/01-self-healing-web-app/) | First "real" app: compute, health probes, monitoring, automation | 2 wks | ⭐⭐ |
| 4 | [03 · Zero-Trust Landing Zone](projects/03-zero-trust-landing-zone/) | Networking + identity + governance that later projects plug into | 3 wks | ⭐⭐⭐⭐ |
| 5 | [04 · Serverless Event-Driven Order Pipeline](projects/04-serverless-order-pipeline/) | Messaging, Functions, NoSQL, event-driven design | 2 wks | ⭐⭐⭐ |
| 6 | [08 · Real-Time IoT Telemetry Pipeline](projects/08-iot-telemetry-pipeline/) | Streaming data — builds on event-driven concepts | 2 wks | ⭐⭐⭐ |
| 7 | [02 · Multi-Region Disaster Recovery](projects/02-multi-region-dr/) | Takes project 01 and makes it survive a region outage | 2–3 wks | ⭐⭐⭐⭐ |
| 8 | [07 · GitOps AKS Platform with ArgoCD](projects/07-gitops-aks-argocd/) | Kubernetes — the biggest new skill; best tackled once Azure feels familiar | 3–4 wks | ⭐⭐⭐⭐ |
| 9 | [06 · Threat Detection with Microsoft Sentinel](projects/06-sentinel-threat-detection/) | Needs logs from earlier projects to detect anything interesting | 2 wks | ⭐⭐⭐ |
| 10 | [10 · AI-Powered Log Analyzer](projects/10-ai-log-analyzer/) | Capstone: analyses logs produced by everything you built | 2–3 wks | ⭐⭐⭐⭐ |

\* Assumes ~10–12 hours per week. **Total: about 6 months.** Faster is fine; skipping the write-up is not.

```mermaid
flowchart LR
    F[00 Foundations] --> P9[09 OIDC CI/CD]
    P9 --> P5[05 Cost Watchdog]
    P5 --> P1[01 Self-Healing App]
    P1 --> P3[03 Landing Zone]
    P3 --> P4[04 Serverless Orders]
    P4 --> P8[08 IoT Telemetry]
    P1 --> P2[02 Multi-Region DR]
    P3 --> P2
    P3 --> P7[07 GitOps AKS]
    P1 & P4 & P7 --> P6[06 Sentinel]
    P6 --> P10[10 AI Log Analyzer]
```

---

## 2. Phases & milestones

### Phase 0 — Foundations (weeks 1–3)
- [ ] Create an Azure account (free account gives credit for 30 days) and **set a budget alert on day 1**
- [ ] Install: Azure CLI, Terraform, Git, VS Code (+ Terraform & Azure extensions), Docker
- [ ] Work through [docs/00-foundations.md](docs/00-foundations.md)
- [ ] Deploy and destroy one resource group with a storage account using Terraform
- **Milestone:** you can explain subscription → resource group → resource, and run `terraform plan/apply/destroy` without notes.

### Phase 1 — Delivery & guardrails (weeks 4–6) · Projects 09, 05
- **Milestone:** a push to `main` deploys infra through GitHub Actions with **zero stored secrets**, and you get an email + automatic shutdown when spend crosses a threshold.

### Phase 2 — Core cloud architecture (weeks 7–13) · Projects 01, 03
- **Milestone:** a web app that heals itself, running inside a hub-and-spoke network with Azure Policy guardrails and private endpoints.

### Phase 3 — Event-driven & data (weeks 14–17) · Projects 04, 08
- **Milestone:** two asynchronous pipelines with retries, dead-lettering, and dashboards.

### Phase 4 — Resilience & platforms (weeks 18–24) · Projects 02, 07
- **Milestone:** a recorded failover drill with measured RTO/RPO, and an AKS cluster where `git push` is the only way to deploy.

### Phase 5 — Security & AI (weeks 25–29) · Projects 06, 10
- **Milestone:** Sentinel detects a simulated attack and runs an automated response; an LLM summarises incidents and suggests root causes.

---

## 3. Definition of "done" for every project

A project is finished only when its folder contains all of this:

- [ ] `README.md` — problem, architecture diagram, design decisions, how to deploy, how to tear down, cost, lessons learned
- [ ] `docs/architecture.png` (or `.drawio` / Mermaid) — see [diagram tips](docs/diagrams.md)
- [ ] `infra/` — Terraform (or Bicep), formatted, validated, no hard-coded secrets
- [ ] `src/` — application / function code (if any)
- [ ] A GitHub Actions workflow in `.github/workflows/` that deploys it via OIDC
- [ ] A **demo**: screenshots or a 2-minute screen recording (GIF/MP4) showing it working
- [ ] An **interview story** written down (see [docs/interview-guide.md](docs/interview-guide.md))
- [ ] Resources **destroyed** after the demo (`terraform destroy`) — keep the code, not the bill

---

## 4. Cost rules (read before every project)

1. Budget alert on the subscription before you deploy anything ([project 05](projects/05-cost-watchdog/) automates this).
2. Tag every resource: `project=<nn>`, `owner=jaival`, `env=dev`. Tags make cost reports useful.
3. **Deploy → demo → screenshot → destroy.** IaC means you can rebuild in minutes.
4. Watch the expensive ones: Azure Firewall, AKS node pools, Application Gateway/WAF, Front Door Premium, Sentinel data ingestion, Azure OpenAI tokens, SQL vCore tiers. Each project README lists its cost hot-spots.
5. Use the [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/) before deploying anything you're unsure about.

---

## 5. Certifications that line up with this roadmap (optional)

| After phase | Certification | Why |
|---|---|---|
| 0–1 | **AZ-900** Azure Fundamentals | Vocabulary; easy win |
| 2–3 | **AZ-104** Azure Administrator | Networking, identity, compute, storage — exactly projects 01/03 |
| 4 | **AZ-305** Solutions Architect Expert (needs AZ-104) | DR, landing zones, design trade-offs — projects 02/03 |
| 4 | **CKA / CKAD** | If project 07 hooked you on Kubernetes |
| 5 | **SC-200** Security Operations Analyst | Sentinel, KQL — project 06 |
| — | **AZ-400** DevOps Engineer Expert | CI/CD, GitOps — projects 07/09 |
| — | **Terraform Associate** | Used in every project |

Projects + one associate cert (AZ-104) is a strong combination for junior/mid cloud roles.
