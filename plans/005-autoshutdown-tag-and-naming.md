# Plan 005: Every Terraform folder sets the `autoshutdown` tag and the README naming rule matches the code

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md` — unless a reviewer dispatched you and told you they
> maintain the index.
>
> **Drift check (run first)**: `git diff --stat 8c744d3..HEAD -- foundations README.md CLAUDE.md`
> If any in-scope file changed since this plan was written, compare the
> "Current state" excerpts against the live code before proceeding. Earlier
> plans in `plans/README.md` deliberately edit some of the same files, so line
> numbers may have shifted: **locate text by its content, not its line
> number**. If the quoted text itself is missing or different, that is a STOP
> condition.

## Status

- **Priority**: P1
- **Effort**: S
- **Risk**: LOW
- **Depends on**: none (run after 004: same batch, same branch)
- **Category**: tech-debt
- **Batch**: 2 (see `plans/README.md`)
- **Planned at**: commit `8c744d3`, 2026-11-13

## Why this matters

`README.md` and `ROADMAP.md` say every resource carries four lowercase tags:
`project`, `owner`, `env`, `autoshutdown`. The Terraform sets only three.
Project 05 (the cost watchdog, built second) finds resources to stop by the
`autoshutdown` tag, so today's code would be invisible to it — and every later
project will copy this code. Separately, the README's naming rule
(`<type>-<project>-<env>-<region-short>`) is contradicted by both its own
examples and the code. Fix the tag in code; fix the naming rule in the doc
(renaming resources is not worth it).

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

**Tags today** (three keys everywhere):

`foundations/01-hello-storage/aws/main.tf`:
```hcl
  default_tags {
    tags = {
      project = var.project
      env     = var.env
      owner   = var.owner
    }
  }
```
`foundations/01-hello-storage/azure/main.tf`:
```hcl
locals {
  tags = {
    project = var.project
    env     = var.env
    owner   = var.owner
  }
}
```
`foundations/01-hello-storage/gcp/main.tf`:
```hcl
  default_labels = {
    project = var.project
    env     = var.env
    owner   = var.owner
  }
```
The three `foundations/02-state-backend/{aws,azure,gcp}/main.tf` files have the same three blocks but with literals:
```hcl
      project = "tfstate"
      env     = "shared"
      owner   = var.owner
```

**Variables today**: each `foundations/01-hello-storage/<cloud>/variables.tf` defines `project`, `env`, `region`, `owner` (identical on all clouds except the region default). Every one contains this block:
```hcl
variable "owner" {
  description = "Owner tag/label (lowercase so it is valid on GCP too)."
  type        = string
  default     = "jaival"
}
```
In the GCP file that block is followed by a comment and `variable "gcp_project_id"`.

**Docs today**:
- `README.md` (Conventions section):
```
- **Naming**: `<type>-<project>-<env>-<region-short>`, e.g. `rg-p01-dev-cin`, `p01-dev-aps1-alb`. Follow each cloud's naming rules (S3/GCS buckets are globally unique; Azure storage accounts allow no dashes).
```
- `foundations/README.md` (Exercise 1):
```
storage bucket — built three ways. Each folder takes the **same variables** (`project`, `env`,
`region`, `owner`) and returns the **same outputs** (`bucket_name`, `bucket_url`). That's the pattern
```
- Actual names in code: Azure `rg-${var.project}-${var.env}-hello`, `st${var.project}${var.env}<hex>`; AWS/GCP `${var.project}-${var.env}-hello-<hex>`.

Rule to honor: tag keys and values must be lowercase strings (GCP labels reject anything else). Sibling cloud folders must keep **identical** variable names.

## Commands you will need

**Terraform CLI**: run `terraform version`. You need 1.10 or newer (CI uses 1.13.x).
If the command is missing, download the Linux zip for the newest 1.13.x from
`https://releases.hashicorp.com/terraform/`, unzip it into a directory **outside
the repo** (e.g. `$HOME/bin`) and put it on `PATH`. If you cannot install it,
STOP and report. `terraform init` creates `.terraform/` folders; they are
git-ignored — leave them, never commit them.

| Purpose | Command | Expected on success |
|---|---|---|
| Auto-format | `terraform fmt -recursive foundations` | exit 0 (it re-aligns the `=` signs; that is expected) |
| Format check | `terraform fmt -check -recursive -diff` | exit 0, no output |
| Validate all six | `for d in foundations/*/*/; do (cd "$d" && terraform init -backend=false -input=false >/dev/null && terraform validate) || echo "FAILED $d"; done` | six times `Success! The configuration is valid.`, no `FAILED` |
| Tag present everywhere | `grep -L 'autoshutdown' foundations/*/*/main.tf` | no output |

## Scope

**In scope**:
- `foundations/01-hello-storage/{aws,azure,gcp}/main.tf` and `variables.tf`
- `foundations/02-state-backend/{aws,azure,gcp}/main.tf`
- `README.md` (the Naming bullet only)
- `foundations/README.md` (the two lines quoted above only)
- `CLAUDE.md` (one phrase, only if the file exists)
- `plans/README.md` (status row only)

**Out of scope** (do NOT touch):
- Resource names in any `.tf` file — the naming fix is documentation-only.
- `outputs.tf` files and `.terraform.lock.hcl` files (revert any lock-file change `terraform init` makes).
- `foundations/02-state-backend/*/variables.tf` — the state backends get a literal, not a variable.
- `ROADMAP.md` and `projects/` — already correct.

## Git workflow

- Branch: `improve/batch-2` (create it from `main` if it does not exist; if it exists, continue on it — all plans of one batch share one branch).
- One commit for this plan. Message style is conventional commits, e.g. `feat: add autoshutdown tag to all foundations Terraform`.
- **Commit identity is mandatory** — commit with exactly:
  `git -c user.name="Jaival" -c user.email="Jaival@users.noreply.github.com" commit -m "<message>"`
  Never use any other name or email address. Do not put URLs, session links or
  tool names in the commit message.
- Do NOT push, merge, or open a PR unless the operator explicitly instructs it.

## Steps

### Step 1: Add the variable to the three hello-storage folders

In each of `foundations/01-hello-storage/aws/variables.tf`, `.../azure/variables.tf`, `.../gcp/variables.tf`, insert this block **directly after** the `variable "owner"` block (blank line before and after). In the GCP file that puts it before the `# GCP is the only cloud that needs this` comment.

```hcl
variable "autoshutdown" {
  description = "May the cost watchdog (project 05) stop these resources outside working hours?"
  type        = bool
  default     = true
}
```

**Verify**: `grep -c 'variable "autoshutdown"' foundations/01-hello-storage/*/variables.tf` → `1` for each of the three files.

### Step 2: Add the tag to the three hello-storage folders

In each `foundations/01-hello-storage/<cloud>/main.tf`, add one line to the tag map quoted in "Current state", after the `owner` line:

```hcl
autoshutdown = tostring(var.autoshutdown) # "true" / "false" — tag values must be strings
```

Then run `terraform fmt -recursive foundations`.

**Verify**: `grep -c 'tostring(var.autoshutdown)' foundations/01-hello-storage/*/main.tf` → `1` for each of the three files.

### Step 3: Add the tag to the three state backends (literal `"false"`)

In each `foundations/02-state-backend/<cloud>/main.tf`, add one line to the tag map after the `owner` line:

```hcl
autoshutdown = "false" # state storage must never be stopped or cleaned up by the watchdog
```

Then run `terraform fmt -recursive foundations`.

**Verify**: the "Tag present everywhere", "Format check" and "Validate all six" commands from the table all give the expected result.

### Step 4: Fix the docs

1. `README.md` — replace the Naming bullet quoted in "Current state" with:
```
- **Naming**: Azure `<type>-<project>-<env>-<name>` (e.g. `rg-p01-dev-web`); AWS and GCP `<project>-<env>-<name>` (e.g. `p01-dev-web-alb`). Add a short region code (`cin`, `aps1`, `as1`) only when one project deploys to more than one region (project 02), and a random suffix where names are globally unique (S3/GCS buckets, Azure storage accounts — which also allow no dashes).
```
2. `foundations/README.md` — in the two lines quoted in "Current state", change `` (`project`, `env`, `` / `` `region`, `owner`) `` so the list reads `` (`project`, `env`, `region`, `owner`, `autoshutdown`) `` (re-wrap the line near 100 characters as needed; change nothing else).
3. `CLAUDE.md` — only if it exists: change `(at minimum `project`, `env`, `region`, `owner`)` to `(at minimum `project`, `env`, `region`, `owner`, `autoshutdown`)`.

**Verify**: `grep -c 'region-short' README.md` → `0`; `grep -c 'autoshutdown' foundations/README.md` → `1`.

## Test plan

No automated tests yet. Plan 007 adds mocked tests and will assert the tag set; it depends on this plan.

## Done criteria

- [ ] `terraform fmt -check -recursive -diff` exits 0
- [ ] All six folders validate (command in the table, no `FAILED`)
- [ ] `grep -L 'autoshutdown' foundations/*/*/main.tf` prints nothing
- [ ] `git diff --stat` touches no `outputs.tf` and no `.terraform.lock.hcl`
- [ ] `plans/README.md` status row for 005 updated

## STOP conditions

- The text quoted in "Current state" is not present in the file (the repo has drifted).
- A step's verification fails twice after a reasonable fix attempt.
- The fix appears to require touching a file outside the in-scope list.
- Any command asks for cloud credentials or would contact a real cloud account.
- A tag map in any of the six `main.tf` files has keys other than `project`, `env`, `owner` (someone changed the tagging scheme).
- `terraform validate` on the GCP folders rejects the label (would mean a value is not a lowercase string).

## Maintenance notes

- Every future `infra/<cloud>/` folder should copy the `autoshutdown` variable and tag line. Plan 007's tests enforce it for `foundations/` only.
- On Azure, tags are not inherited by default: resources must each get `tags = local.tags`. Reviewer: check no Azure resource lost its `tags` argument.
