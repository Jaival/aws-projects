# How to talk about these projects in interviews

## The 2-minute project story (STAR + trade-offs)

Practise this out loud for each project:

1. **Situation / problem** (15s) — "Teams lose money when dev environments run all weekend…"
2. **What I built** (30s) — one sentence on the architecture, pointing at the diagram.
3. **How it works** (30s) — the 3–4 numbered steps of the main flow.
4. **A decision I made and why** (30s) — "I chose Service Bus over Event Grid for orders because I needed ordered, at-least-once delivery with dead-lettering…"
5. **Something that broke and how I fixed it** (15s) — interviewers love real debugging stories. Keep notes as you build!
6. **Result / numbers** (10s) — "Failover took 94 seconds; RPO under 5 seconds." "Cut idle cost by ~60%."

## Write these down while you build (not afterwards)

Keep a `docs/notes.md` in each project folder with:
- Errors you hit and how you solved them
- Alternatives you considered (and why you rejected them)
- Numbers: latency, cost per month, failover time, messages/sec
- What you'd do differently in production

## Questions you should expect for every project

- How would this scale to 10× / 100× the traffic?
- What happens if \<component\> fails?
- How is it secured? Where are the secrets? (Answer: there aren't any — managed identity / OIDC.)
- How much does it cost, and how would you reduce it?
- How do you deploy changes safely? How do you roll back?
- How do you know it's working? (Monitoring, alerts, dashboards.)

## Multi-cloud questions (expect these now)

- **"Why did you build it on three clouds?"** → To learn the patterns behind the products. You can then pick the right tool for a team instead of defaulting to the one you know.
- **"Would you recommend multi-cloud to a company?"** → Usually not for a single workload: it doubles the skills needed, adds egress cost, and you end up on the lowest common denominator. It does make sense for acquisitions, regulation, best-of-breed services (e.g. BigQuery for analytics) or negotiating leverage. Having a nuanced answer is what makes you sound senior.
- **"What was different on each cloud?"** → Quote your `comparison.md` files: IAM models, AWS's per-AZ subnets vs GCP's global VPC, three ways to write a saga, measured failover times.
- **"How did you keep the code portable?"** → Adapters (ports & adapters), OpenTelemetry, containers, Terraform modules with the same interface — and where you *chose* lock-in on purpose because the managed service was worth it.

## The Well-Architected lens

All three clouds publish a **Well-Architected Framework** (AWS adds a sixth pillar, *sustainability*).
Framing answers in these terms signals seniority:

| Pillar | Example sentence |
|---|---|
| Reliability | "Zone-redundant App Service plus health-check-based instance replacement." |
| Security | "No public endpoints on data services — private endpoints and managed identity only." |
| Cost optimisation | "Auto-shutdown on tagged dev resources, budget alerts at 50/80/100%." |
| Operational excellence | "Everything is Terraform, deployed through PR-gated pipelines." |
| Performance efficiency | "Autoscale on queue length rather than CPU, because the workload is I/O bound." |
