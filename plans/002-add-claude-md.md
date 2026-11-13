# Plan 002: The repo has a CLAUDE.md that states its rules for agents and contributors

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md` — unless a reviewer dispatched you and told you they
> maintain the index.
>
> **Drift check (run first)**: `git diff --stat 8c744d3..HEAD -- CLAUDE.md`
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
- **Depends on**: none
- **Category**: dx
- **Batch**: 1 (see `plans/README.md`)
- **Planned at**: commit `8c744d3`, 2026-11-13

## Why this matters

The rules that keep this repo coherent — identical Terraform inputs/outputs on
all three clouds, lowercase tags, no secrets, which checks to run, and the
owner's required commit identity — are written nowhere in the repo. Every agent
session (including the ones executing these plans) has to be told them again,
and one that isn't told will commit with the wrong author or break cross-cloud
parity. A `CLAUDE.md` at the repo root is loaded automatically by Claude Code.

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

- There is no `CLAUDE.md` or `AGENTS.md` at the repo root (`ls CLAUDE.md AGENTS.md` → both "No such file").
- The facts in the file below were verified against the repo at the planned-at commit. Do not "improve" or extend them.

## Commands you will need

| Purpose | Command | Expected on success |
|---|---|---|
| File exists | `test -f CLAUDE.md && echo ok` | `ok` |
| Size sanity | `wc -l < CLAUDE.md` | between 45 and 65 |
| No personal email | `grep -c '@gmail' CLAUDE.md` | `0` |

## Scope

**In scope**:
- `CLAUDE.md` (create)
- `plans/README.md` (status row only)

**Out of scope** (do NOT touch):
- `README.md`, `ROADMAP.md`, anything under `docs/`, `foundations/`, `projects/` — this plan only adds one file.
- `.claude/` — vendored skill.
- Do not also create `AGENTS.md`.

## Git workflow

- Branch: `improve/batch-1` (create it from `main` if it does not exist; if it exists, continue on it — all plans of one batch share one branch).
- One commit for this plan. Message style is conventional commits, e.g. `docs: add CLAUDE.md with repo rules`.
- **Commit identity is mandatory** — commit with exactly:
  `git -c user.name="Jaival" -c user.email="Jaival@users.noreply.github.com" commit -m "<message>"`
  Never use any other name or email address. Do not put URLs, session links or
  tool names in the commit message.
- Do NOT push, merge, or open a PR unless the operator explicitly instructs it.

## Steps

### Step 1: Create `CLAUDE.md`

Create `CLAUDE.md` at the repo root with **exactly** this content (everything between the two marker lines, not the markers themselves):

<<<<<<<< BEGIN CLAUDE.md
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

- **Same inputs and outputs on every cloud.** Sibling `aws/`, `azure/`, `gcp/` folders take the same variables (at minimum `project`, `env`, `region`, `owner`) and return the same output names. GCP may add `gcp_project_id`; document any other difference in a comment.
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
>>>>>>>> END CLAUDE.md

**Verify**: all three commands in "Commands you will need" give the expected result, and `grep -c 'BEGIN CLAUDE.md\|END CLAUDE.md' CLAUDE.md` → `0`.

## Test plan

None — documentation only.

## Done criteria

- [ ] `test -f CLAUDE.md` succeeds; `grep -c 'Jaival@users.noreply.github.com' CLAUDE.md` returns `2`
- [ ] `grep -c '@gmail' CLAUDE.md` returns `0`
- [ ] `git status --short` lists only `CLAUDE.md` and `plans/README.md`
- [ ] `plans/README.md` status row for 002 updated

## STOP conditions

- The text quoted in "Current state" is not present in the file (the repo has drifted).
- A step's verification fails twice after a reasonable fix attempt.
- The fix appears to require touching a file outside the in-scope list.
- Any command asks for cloud credentials or would contact a real cloud account.
- `CLAUDE.md` or `AGENTS.md` already exists.

## Maintenance notes

- Plan 005 adds the `autoshutdown` variable; plan 007 adds `terraform test`. Each of those plans updates this file itself.
- Keep this file short. It is loaded into every agent session; detail belongs in `README.md` / `ROADMAP.md`.
