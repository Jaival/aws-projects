# Multi-cloud engineering projects — working rules

Ten cloud projects, each designed once and built on **AWS, Azure and GCP** with Terraform.
Read `README.md` and `ROADMAP.md` for the plan; this file is the rules for changing the repo.

## Layout

- `foundations/` — Phase 0 exercises (`01-hello-storage`, `02-state-backend`), one folder per cloud.
- `projects/NN-name/` — one folder per project: `README.md` (guide), `docs/`, `src/`, `infra/{aws,azure,gcp}/`.
- `docs/` — foundations reading, the AWS ↔ Azure ↔ GCP service map, diagram and interview guides.
- `plans/` — implementation plans written by the `improve` skill. Follow a plan exactly; update its row in `plans/README.md`.
- `.claude/skills/improve/` — vendored third-party skill. Do not edit.

## Rules for Terraform

- **Same inputs and outputs on every cloud.** Sibling `aws/`, `azure/`, `gcp/` folders take the same variables (at minimum `project`, `env`, `region`, `owner`, `autoshutdown`) and return the same output names. GCP may add `gcp_project_id`; document any other difference in a comment.
- **Tags / labels are lowercase** (GCP requires it): `project`, `env`, `owner`, `autoshutdown`. Apply them through provider defaults (`default_tags`, `default_labels`) or a `local.tags` map on Azure.
- **No secrets, ever.** No keys, passwords or tokens in code, variables, state or docs. CI uses OIDC; storage uses identity-based access (Azure: `shared_access_key_enabled = false`).
- Storage is private, versioned and encrypted by default. Say why in a comment when you deviate.
- Comments explain *why* in plain English for a learner. Keep them; add them for anything non-obvious.
- Commit `.terraform.lock.hcl`. Never commit `.terraform/`, `*.tfstate`, `*.tfvars` (see `.gitignore`).
- Default regions: AWS `ap-south-1`, Azure `centralindia`, GCP `asia-south1` (DR: `ap-south-2`, `southindia`, `asia-south2`).

## Checks to run before committing

```bash
terraform fmt -check -recursive -diff
```

```bash
cd <changed terraform folder> && terraform init -backend=false -input=false && terraform validate
```

```bash
cd <changed terraform folder> && terraform test
```

```bash
bash -n scripts/check-tools.sh
```

CI (`.github/workflows/terraform-checks.yml`) runs the first two on every pull request.
Never run `terraform plan`, `apply` or `destroy` against a real cloud unless the owner asks in that session.

## Docs

- Project guides are written Azure-first with a "Multi-cloud implementation" table; keep all three clouds in step when you change one.
- Diagrams are Mermaid inside Markdown. Node IDs must be unique, including against subgraph IDs.
- Use relative links between files and check they resolve.

## Git

- Conventional commit subjects: `feat:`, `fix:`, `docs:`, `ci:`, `chore:`.
- Commit as `Jaival <Jaival@users.noreply.github.com>`:
  `git -c user.name="Jaival" -c user.email="Jaival@users.noreply.github.com" commit ...`
  Never put a personal email address or a session link in a commit.
- Do not push, force-push or open a pull request unless asked.
