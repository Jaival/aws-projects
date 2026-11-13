# Plan 008: GitHub Actions are pinned to commit SHAs and Dependabot keeps them and the Terraform providers current

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md` — unless a reviewer dispatched you and told you they
> maintain the index.
>
> **Drift check (run first)**: `git diff --stat 8c744d3..HEAD -- .github`
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
- **Depends on**: plans/001 and 007 (they edit the same workflow file; run this last)
- **Category**: security
- **Batch**: 3 (see `plans/README.md`)
- **Planned at**: commit `8c744d3`, 2026-11-13

## Why this matters

The workflow references third-party actions by a moving tag (`@v4`, `@v3`).
Whoever controls that tag controls what runs in this repo's CI. Today the
workflow has no cloud access, but project 09 gives CI the ability to deploy to
three clouds — and that project's own guide teaches "pin third-party actions
to a commit SHA; use Dependabot for action updates". The repo should already
follow its own advice. Dependabot then proposes updates as pull requests, so
pinning does not mean going stale.

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

- `.github/workflows/terraform-checks.yml` — the only workflow. It has exactly five `uses:` lines:
  - `- uses: actions/checkout@v4` — three times (jobs `fmt`, `discover`, `validate`)
  - `- uses: hashicorp/setup-terraform@v3` — twice (jobs `fmt`, `validate`)
- `.github/dependabot.yml` does not exist.
- Terraform folders live at `foundations/<exercise>/<cloud>/` today and will live at `projects/<name>/infra/<cloud>/` later. Each has a committed `.terraform.lock.hcl`.
- Commit subjects in this repo use conventional prefixes (`ci:`, `chore:`, `docs:`, `feat:`, `fix:`).

## Commands you will need

| Purpose | Command | Expected on success |
|---|---|---|
| List release tags + SHAs | `git ls-remote --tags https://github.com/actions/checkout 'v4.*'` (and the same for `https://github.com/hashicorp/setup-terraform 'v3.*'`) | lines of `<40-hex sha>\trefs/tags/vX.Y.Z`, some followed by a second line ending `^{}` |
| No unpinned actions | `grep -nE '^\s*-?\s*uses:' .github/workflows/*.yml \| grep -vE '@[0-9a-f]{40} # v[0-9]+\.[0-9]+\.[0-9]+$'` | no output |
| YAML parses | `python3 -c "import yaml; [yaml.safe_load(open(f)) for f in ('.github/workflows/terraform-checks.yml','.github/dependabot.yml')]; print('ok')"` | `ok` |

## Scope

**In scope**:
- `.github/workflows/terraform-checks.yml` (only the five `uses:` lines)
- `.github/dependabot.yml` (create)
- `plans/README.md` (status row only)

**Out of scope** (do NOT touch):
- Upgrading to a new **major** version of either action (stay on `actions/checkout` v4.x and `hashicorp/setup-terraform` v3.x) — Dependabot will propose majors separately, where they can be reviewed.
- `terraform_version: "~1.13"` and everything else in the workflow.
- Any `.terraform.lock.hcl` or provider version constraint.

## Git workflow

- Branch: `improve/batch-3` (create it from `main` if it does not exist; if it exists, continue on it — all plans of one batch share one branch).
- One commit for this plan. Message style is conventional commits, e.g. `ci: pin actions to commit SHAs and add Dependabot`.
- **Commit identity is mandatory** — commit with exactly:
  `git -c user.name="Jaival" -c user.email="Jaival@users.noreply.github.com" commit -m "<message>"`
  Never use any other name or email address. Do not put URLs, session links or
  tool names in the commit message.
- Do NOT push, merge, or open a PR unless the operator explicitly instructs it.

## Steps

### Step 1: Resolve the SHAs

For each action, run the "List release tags" command and pick the **highest** `vMAJOR.MINOR.PATCH` tag within the current major (v4.x.y for checkout, v3.x.y for setup-terraform). The SHA to use is the commit SHA: if the tag has a second line ending in `^{}`, use the SHA on **that** line; otherwise use the SHA on the tag's only line. Record `tag` and `sha` for both actions.

**Verify**: each SHA is 40 lowercase hex characters, and `git ls-remote https://github.com/<owner>/<repo> | grep <sha>` shows it attached to the tag you chose.

### Step 2: Pin the five `uses:` lines

Replace every `actions/checkout@v4` with `actions/checkout@<sha> # <tag>` and every `hashicorp/setup-terraform@v3` with `hashicorp/setup-terraform@<sha> # <tag>`, e.g. (illustrative SHA — use the one you resolved):

```yaml
      - uses: actions/checkout@0123456789abcdef0123456789abcdef01234567 # v4.9.9
```

The trailing `# vX.Y.Z` comment is required: Dependabot reads and updates it.

**Verify**: the "No unpinned actions" command prints nothing; `grep -c 'uses:' .github/workflows/terraform-checks.yml` → `5`.

### Step 3: Add Dependabot

Create `.github/dependabot.yml`:

```yaml
# Opens pull requests when a pinned GitHub Action or a Terraform provider has a new version.
version: 2
updates:
  - package-ecosystem: github-actions
    directory: /
    schedule:
      interval: weekly
    commit-message:
      prefix: ci

  - package-ecosystem: terraform
    directories:
      - /foundations/*/*
      - /projects/*/infra/*
    schedule:
      interval: monthly
    commit-message:
      prefix: chore
    groups:
      terraform-providers:
        patterns:
          - "*"
```

**Verify**: the "YAML parses" command → `ok`.

## Test plan

Not unit-testable locally. After the operator pushes the branch: the `terraform-checks` workflow must still run green, and GitHub → Insights → Dependency graph → Dependabot must list both ecosystems without a config error.

## Done criteria

- [ ] "No unpinned actions" prints nothing
- [ ] Both YAML files parse
- [ ] `git diff 8c744d3 -- .github/workflows/terraform-checks.yml | grep '^[-+]' | grep -v 'uses:' | grep -vE '^(\+\+\+|---)'` shows only lines added by plans 001 and 007 (the `all-checks` job and the `terraform test` step) — nothing else changed by this plan
- [ ] `plans/README.md` status row for 008 updated, recording the two tags and SHAs used

## STOP conditions

- The text quoted in "Current state" is not present in the file (the repo has drifted).
- A step's verification fails twice after a reasonable fix attempt.
- The fix appears to require touching a file outside the in-scope list.
- Any command asks for cloud credentials or would contact a real cloud account.
- `git ls-remote` cannot reach github.com, or returns no `v4.*` / `v3.*` tags — do not guess or invent a SHA; report.
- The workflow has `uses:` lines other than the two actions listed (a new action was added) — pin it the same way only if it is from `actions/*`, `hashicorp/*`, `aws-actions/*`, `azure/*` or `google-github-actions/*`; otherwise report.

## Maintenance notes

- Dependabot pull requests are authored by `dependabot[bot]`; that is expected and unrelated to the owner's commit-identity rule.
- If the `projects/*/infra/*` glob matches nothing yet, Dependabot simply ignores it.
- Every new workflow added in project 09 must pin by SHA too; the "No unpinned actions" command is a good CI check to add there.
- Reviewer: confirm the SHAs on github.com (`https://github.com/actions/checkout/commit/<sha>`) really belong to the stated tags.
