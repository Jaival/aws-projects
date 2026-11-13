# Plan 003: The project 09 guide and README layout match what the repo already contains

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md` — unless a reviewer dispatched you and told you they
> maintain the index.
>
> **Drift check (run first)**: `git diff --stat 8c744d3..HEAD -- projects/09-secrets-free-cicd-oidc/README.md README.md`
> If any in-scope file changed since this plan was written, compare the
> "Current state" excerpts against the live code before proceeding. Earlier
> plans in `plans/README.md` deliberately edit some of the same files, so line
> numbers may have shifted: **locate text by its content, not its line
> number**. If the quoted text itself is missing or different, that is a STOP
> condition.

## Status

- **Priority**: P2
- **Effort**: S
- **Risk**: LOW
- **Depends on**: none
- **Category**: docs
- **Batch**: 1 (see `plans/README.md`)
- **Planned at**: commit `8c744d3`, 2026-11-13

## Why this matters

Project 09 (OIDC CI/CD) is the next thing the owner builds, and its guide is
stale in ways that will cost real time: (a) it hard-codes the repository name
`Jaival/aws-projects` inside the OIDC *subject* examples, but the owner is about
to rename the repo — a trust rule copied from the guide would silently stop
matching; (b) it tells the reader to build a `bootstrap/` config for Terraform
state, which Phase 0 already provides in `foundations/02-state-backend/`;
(c) it lists "do the same for AWS" as a stretch goal although AWS and GCP are
now core scope; (d) the root README's layout tree shows folders that don't exist yet
without saying so.

## Current state

**About this repo** (you have not seen it before): a learning/portfolio repo of
10 cloud projects, each to be built on AWS, Azure and GCP with Terraform. Today
it holds only documentation (`README.md`, `ROADMAP.md`, `docs/`, `projects/*/README.md`)
and "Phase 0" exercises under `foundations/`: six small Terraform folders
(`foundations/01-hello-storage/{aws,azure,gcp}` and
`foundations/02-state-backend/{aws,azure,gcp}`), plus one CI workflow
(`.github/workflows/terraform-checks.yml`) and one script (`scripts/check-tools.sh`).
Nothing is deployed anywhere and **you have no cloud credentials — never run
`terraform plan`, `terraform apply` or `terraform destroy` against a real cloud.**

File `projects/09-secrets-free-cicd-oidc/README.md` (line numbers at the planned-at commit):

- Line 24, inside a Mermaid `sequenceDiagram`:
```
    GHOIDC-->>GH: signed JWT (sub=repo:Jaival/aws-projects:environment:prod)
```
- Line 58 (one long line):
```
- In Entra ID you create a **federated identity credential** on an app registration (or user-assigned managed identity) that says: *"trust tokens from GitHub's issuer **only** if the subject is `repo:Jaival/aws-projects:environment:prod`."*
```
- Line 69:
```
Pattern to aim for: **two identities** — a read-only "plan" identity for PRs and a "deploy" identity locked to the `prod` environment.
```
- Line 74:
```
- Bootstrap problem: the state storage account must exist before Terraform can use it → create it once with a small script or a separate `bootstrap/` Terraform config.
```
- Line 90:
```
1. **Bootstrap**: resource group + storage account + container for Terraform state (script in `bootstrap/`).
```
- Line 104:
```
- Do the same for AWS (`aws-actions/configure-aws-credentials` with an IAM OIDC provider) — great talking point since your repo started as `aws-projects`.
```

File `README.md`, lines 77–79, inside a fenced code block showing the repo tree:
```
├── modules/                        # shared Terraform modules, per cloud
│   ├── aws/  ├── azure/  └── gcp/
├── .github/workflows/              # reusable multi-cloud Terraform workflow (project 09)
```

Facts you need: `foundations/02-state-backend/{aws,azure,gcp}/` exist and create the state storage on each cloud. `modules/` does not exist yet. `.github/workflows/` contains only `terraform-checks.yml` (format + validate).

## Commands you will need

| Purpose | Command | Expected on success |
|---|---|---|
| Old repo name gone from guide | `grep -c 'aws-projects' projects/09-secrets-free-cicd-oidc/README.md` | `0` |
| No bootstrap/ folder references | `grep -c 'bootstrap/' projects/09-secrets-free-cicd-oidc/README.md` | `0` |
| Link target exists | `test -d foundations/02-state-backend && echo ok` | `ok` |

## Scope

**In scope**:
- `projects/09-secrets-free-cicd-oidc/README.md` (only the six lines listed, plus one inserted note)
- `README.md` (only lines 77–79 of the tree)
- `plans/README.md` (status row only)

**Out of scope** (do NOT touch):
- `README.md` line 11, the badge URL containing `aws-projects` — it must change only **after** the owner renames the repo on GitHub; changing it now breaks the badge.
- `README.md` lines 99–100 (Naming / Tags bullets) — plan 005 owns them.
- Any other project guide, and any other wording in the project 09 guide. Do not rewrite sections.

## Git workflow

- Branch: `improve/batch-1` (create it from `main` if it does not exist; if it exists, continue on it — all plans of one batch share one branch).
- One commit for this plan. Message style is conventional commits, e.g. `docs: sync project 09 guide with Phase 0 and multi-cloud scope`.
- **Commit identity is mandatory** — commit with exactly:
  `git -c user.name="Jaival" -c user.email="Jaival@users.noreply.github.com" commit -m "<message>"`
  Never use any other name or email address. Do not put URLs, session links or
  tool names in the commit message.
- Do NOT push, merge, or open a PR unless the operator explicitly instructs it.

## Steps

### Step 1: Replace the hard-coded repo name (lines 24 and 58)

In both lines replace the text `repo:Jaival/aws-projects:environment:prod` with `repo:OWNER/REPO:environment:prod`. Change nothing else on those lines.

**Verify**: `grep -c 'aws-projects' projects/09-secrets-free-cicd-oidc/README.md` → `1` (only line 104 remains, fixed in step 4); `grep -c 'repo:OWNER/REPO:environment:prod' projects/09-secrets-free-cicd-oidc/README.md` → `3` (two new + one that already exists in the subject table).

### Step 2: Add a rename warning after line 69

Directly after the "Pattern to aim for" line (line 69), insert a blank line and then this blockquote, followed by a blank line:

```
> ⚠️ **The repository name is part of the subject.** `OWNER/REPO` must match the repo's name on GitHub exactly. If the repo is renamed after the trust is set up, every federated credential (Azure), role trust policy (AWS) and attribute condition (GCP) stops matching and logins fail — so settle the repo name **before** building this project.
```

**Verify**: `grep -c 'part of the subject' projects/09-secrets-free-cicd-oidc/README.md` → `1`.

### Step 3: Point the bootstrap text at Phase 0 (lines 74 and 90)

Replace line 74 with:
```
- Bootstrap problem: the state storage must exist before Terraform can use it. Phase 0 already solved this — [`foundations/02-state-backend/`](../../foundations/02-state-backend/) creates it on each cloud with its own local state. Reuse it; don't build a second one.
```

Replace line 90 with:
```
1. **Bootstrap**: already done in Phase 0 ([`foundations/02-state-backend/`](../../foundations/02-state-backend/)). Check the three state stores are deployed and note their `backend_config` outputs. The pipeline identities you create in step 2 will also need data access to them (Azure: `Storage Blob Data Contributor` on the state storage account).
```

**Verify**: `grep -c 'bootstrap/' projects/09-secrets-free-cicd-oidc/README.md` → `0`; `grep -c 'foundations/02-state-backend' projects/09-secrets-free-cicd-oidc/README.md` → `2`.

### Step 4: Replace the stale stretch goal (line 104)

Replace line 104 with:
```
- A weekly scheduled "canary" workflow that only logs in to all three clouds and runs an identity check (`aws sts get-caller-identity`, `az account show`, `gcloud auth list`) — it catches broken trust (expired setup, renamed repo) before a real deploy does.
```

**Verify**: `grep -c 'aws-projects' projects/09-secrets-free-cicd-oidc/README.md` → `0`.

### Step 5: Mark not-yet-existing folders in the root README tree

In `README.md` replace the three tree lines quoted in "Current state" with (keep the comment column aligned as shown; it is inside a code block):

```
├── modules/                        # shared Terraform modules, per cloud (added from project 03 on)
│   ├── aws/  ├── azure/  └── gcp/
├── .github/workflows/              # terraform-checks.yml today; reusable deploy workflow arrives with project 09
```

**Verify**: `grep -c 'added from project 03 on' README.md` → `1`; `grep -c 'arrives with project 09' README.md` → `1`.

## Test plan

Documentation only. Check the two new relative links resolve: from `projects/09-secrets-free-cicd-oidc/`, `ls ../../foundations/02-state-backend/` must list `aws azure gcp`.

## Done criteria

- [ ] All three commands in "Commands you will need" give the expected result
- [ ] `grep -c 'aws-projects' README.md` returns `1` (the badge line, intentionally untouched)
- [ ] `git diff --stat` shows only the two in-scope docs (plus `plans/README.md`)
- [ ] `plans/README.md` status row for 003 updated

## STOP conditions

- The text quoted in "Current state" is not present in the file (the repo has drifted).
- A step's verification fails twice after a reasonable fix attempt.
- The fix appears to require touching a file outside the in-scope list.
- Any command asks for cloud credentials or would contact a real cloud account.
- `grep -c 'aws-projects' README.md` returns `0` before you start — the owner has already renamed the repo and updated the badge; report it and continue only with steps 1–5 as written.

## Maintenance notes

- After the owner renames the repo on GitHub, `README.md` line 11 (badge URL) must be updated to the new name. That is deliberately not in this plan.
- The other nine project guides were only spot-checked in the audit; similar "Azure-only" leftovers may exist there.
