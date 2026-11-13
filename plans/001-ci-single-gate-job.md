# Plan 001: CI has one stable status check that branch protection can require

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md` — unless a reviewer dispatched you and told you they
> maintain the index.
>
> **Drift check (run first)**: `git diff --stat 8c744d3..HEAD -- .github/workflows/terraform-checks.yml foundations/README.md`
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

The CI workflow runs `terraform validate` once per Terraform folder using a
matrix, so each folder produces its own check name (`validate foundations/01-hello-storage/aws`, …).
`foundations/README.md` tells the repo owner to require "the `terraform-checks`
jobs" in branch protection. GitHub requires checks **by exact name**, so every
new Terraform folder (there will be ~36) would be unprotected until someone
adds its name by hand. One final "gate" job with a fixed name fixes this for good.

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

- `.github/workflows/terraform-checks.yml` — the only workflow. Jobs: `fmt`, `discover`, `validate` (matrix). The file currently **ends** with the `validate` job:

```yaml
  validate:
    name: validate ${{ matrix.dir }}
    needs: discover
    if: needs.discover.outputs.dirs != '[]'
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        dir: ${{ fromJson(needs.discover.outputs.dirs) }}
    defaults:
      run:
        working-directory: ${{ matrix.dir }}
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: "~1.13"
      - name: terraform init (no backend)
        run: terraform init -backend=false -input=false
      - name: terraform validate
        run: terraform validate
```

- `foundations/README.md` — Phase 0 exercise guide. Exercise 3, step 3 currently reads (one line):

```
3. Turn on **branch protection** for `main` (Settings → Branches): require a PR and the `terraform-checks` jobs to pass.
```

Conventions: YAML uses 2-space indentation; jobs are separated by one blank line; comments are short plain English.

## Commands you will need

| Purpose | Command | Expected on success |
|---|---|---|
| YAML parses | `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/terraform-checks.yml')); print('ok')"` | prints `ok` |
| Gate job shape | `python3 -c "import yaml; j=yaml.safe_load(open('.github/workflows/terraform-checks.yml'))['jobs']['all-checks']; assert j['name']=='all checks passed' and j['if']=='always()' and sorted(j['needs'])==['discover','fmt','validate']; print('ok')"` | prints `ok` |

## Scope

**In scope** (the only files you should modify):
- `.github/workflows/terraform-checks.yml`
- `foundations/README.md` (one line)
- `plans/README.md` (status row only)

**Out of scope** (do NOT touch):
- The existing `fmt`, `discover` and `validate` jobs — do not rename or reorder them; other plans (007, 008) edit them later.
- The `uses:` version pins — plan 008 handles them.
- GitHub repository settings (branch protection itself) — only the repo owner can change those.

## Git workflow

- Branch: `improve/batch-1` (create it from `main` if it does not exist; if it exists, continue on it — all plans of one batch share one branch).
- One commit for this plan. Message style is conventional commits, e.g. `ci: add single gate job for branch protection`.
- **Commit identity is mandatory** — commit with exactly:
  `git -c user.name="Jaival" -c user.email="Jaival@users.noreply.github.com" commit -m "<message>"`
  Never use any other name or email address. Do not put URLs, session links or
  tool names in the commit message.
- Do NOT push, merge, or open a PR unless the operator explicitly instructs it.

## Steps

### Step 1: Append the gate job

Append this to the **end** of `.github/workflows/terraform-checks.yml`, preceded by one blank line, indented exactly as shown (job key at 2 spaces, like the other jobs):

```yaml
  # One stable check name to require in branch protection, however many folders the matrix has.
  all-checks:
    name: all checks passed
    if: always()
    needs: [fmt, discover, validate]
    runs-on: ubuntu-latest
    steps:
      - name: Fail if any job failed or was cancelled
        run: |
          echo "fmt=${{ needs.fmt.result }} discover=${{ needs.discover.result }} validate=${{ needs.validate.result }}"
          if [[ "${{ contains(needs.*.result, 'failure') }}" == "true" || "${{ contains(needs.*.result, 'cancelled') }}" == "true" ]]; then
            exit 1
          fi
```

Notes: `if: always()` is required — without it the gate is *skipped* when an earlier job fails, and GitHub treats a skipped required check as passing. A `skipped` result for `validate` (no Terraform folders) is intentionally allowed.

**Verify**: both commands in "Commands you will need" → each prints `ok`.

### Step 2: Fix the instruction in the exercise guide

In `foundations/README.md`, replace the Exercise 3 step-3 line quoted in "Current state" with:

```
3. Turn on **branch protection** for `main` (Settings → Branches): require a PR and the **`all checks passed`** status check. That one check covers formatting and every `validate` job, so the rule never needs updating when new Terraform folders are added.
```

**Verify**: `grep -c 'all checks passed' foundations/README.md` → `1`; `grep -c 'terraform-checks. jobs to pass' foundations/README.md` → `0`.

## Test plan

No unit tests apply to a workflow file. The real test is the workflow run on GitHub after the branch is pushed by the operator: the run must show a job named `all checks passed` that is green when all others are green.

## Done criteria

- [ ] Both commands in "Commands you will need" print `ok`
- [ ] `grep -c 'all checks passed' foundations/README.md` returns `1`
- [ ] `git status --short` lists only the in-scope files
- [ ] `plans/README.md` status row for 001 updated

## STOP conditions

- The text quoted in "Current state" is not present in the file (the repo has drifted).
- A step's verification fails twice after a reasonable fix attempt.
- The fix appears to require touching a file outside the in-scope list.
- Any command asks for cloud credentials or would contact a real cloud account.
- The workflow already contains a job named `all-checks`.

## Maintenance notes

- Any new job added to this workflow must also be added to `needs:` of `all-checks`, or it will not block merges. Plans 007 and 008 add *steps*, not jobs, so they do not need this.
- After merge the repo owner must select `all checks passed` in Settings → Branches (it only appears in the list after the workflow has run once).
