# Plan 006: Small gaps closed: LICENSE file, Terraform version check, S3 state version expiry

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md` — unless a reviewer dispatched you and told you they
> maintain the index.
>
> **Drift check (run first)**: `git diff --stat 8c744d3..HEAD -- LICENSE scripts/check-tools.sh foundations/02-state-backend/aws/main.tf`
> If any in-scope file changed since this plan was written, compare the
> "Current state" excerpts against the live code before proceeding. Earlier
> plans in `plans/README.md` deliberately edit some of the same files, so line
> numbers may have shifted: **locate text by its content, not its line
> number**. If the quoted text itself is missing or different, that is a STOP
> condition.

## Status

- **Priority**: P3
- **Effort**: S
- **Risk**: LOW
- **Depends on**: none (run after 005: same batch, same branch)
- **Category**: dx
- **Batch**: 2 (see `plans/README.md`)
- **Planned at**: commit `8c744d3`, 2026-11-13

## Why this matters

Three unrelated small gaps, bundled because each is a few lines:
1. A public portfolio repo without a licence is legally "all rights reserved" — nobody may reuse the code. **The owner must confirm the licence choice; this plan assumes MIT.**
2. `foundations/README.md` requires Terraform ≥ 1.10 (the S3 backend's `use_lockfile` needs it) but `scripts/check-tools.sh` only checks that *some* Terraform is installed.
3. The GCP state bucket keeps only the 10 newest old versions of each state file; the AWS state bucket keeps every version forever.

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

1. No `LICENSE` file exists at the repo root. (`.claude/skills/improve/LICENSE.md` belongs to a vendored tool — unrelated.)

2. `scripts/check-tools.sh` — bash, `set -uo pipefail`, helper functions `ok`, `bad` (sets `FAILED=1`), `warn`. The first loop ends like this, followed by the optional-tools loop:

```bash
    ok "$tool — $v"
  else
    bad "$tool is not installed"
  fi
done

for tool in tflint checkov; do
```

3. `foundations/02-state-backend/aws/main.tf` — S3 bucket `aws_s3_bucket.state` with versioning enabled (`aws_s3_bucket_versioning.state`). The encryption block is followed by the bucket policy:

```hcl
resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Only allow HTTPS access to the state bucket.
resource "aws_s3_bucket_policy" "tls_only" {
```
The AWS provider is pinned `~> 6.0`. For comparison, the GCP equivalent in `foundations/02-state-backend/gcp/main.tf` is a `lifecycle_rule` with `num_newer_versions = 10`.

## Commands you will need

**Terraform CLI**: run `terraform version`. You need 1.10 or newer (CI uses 1.13.x).
If the command is missing, download the Linux zip for the newest 1.13.x from
`https://releases.hashicorp.com/terraform/`, unzip it into a directory **outside
the repo** (e.g. `$HOME/bin`) and put it on `PATH`. If you cannot install it,
STOP and report. `terraform init` creates `.terraform/` folders; they are
git-ignored — leave them, never commit them.

| Purpose | Command | Expected on success |
|---|---|---|
| Shell syntax | `bash -n scripts/check-tools.sh` | exit 0, no output |
| Script still runs | `./scripts/check-tools.sh; echo "exit=$?"` | prints a tool list and `exit=0` or `exit=1` — never a bash error such as `unbound variable` or `syntax error` |
| Format | `terraform fmt -check -recursive -diff` | exit 0, no output |
| Validate | `cd foundations/02-state-backend/aws && terraform init -backend=false -input=false && terraform validate` | `Success! The configuration is valid.` |

## Scope

**In scope**:
- `LICENSE` (create)
- `scripts/check-tools.sh`
- `foundations/02-state-backend/aws/main.tf`
- `plans/README.md` (status row only)

**Out of scope** (do NOT touch):
- `.claude/skills/improve/LICENSE.md`.
- The Azure and GCP state backends; the AWS bucket policy and versioning resources.
- Any other behaviour of `check-tools.sh` (login checks, optional tools).
- `.terraform.lock.hcl` (no new provider is needed; revert any change).

## Git workflow

- Branch: `improve/batch-2` (create it from `main` if it does not exist; if it exists, continue on it — all plans of one batch share one branch).
- One commit for this plan. Message style is conventional commits, e.g. `chore: add LICENSE, Terraform version check and S3 state version expiry`.
- **Commit identity is mandatory** — commit with exactly:
  `git -c user.name="Jaival" -c user.email="Jaival@users.noreply.github.com" commit -m "<message>"`
  Never use any other name or email address. Do not put URLs, session links or
  tool names in the commit message.
- Do NOT push, merge, or open a PR unless the operator explicitly instructs it.

## Steps

### Step 1: Add the MIT licence

Create `LICENSE` at the repo root with the standard MIT License text, first line `MIT License`, copyright line exactly:

```
Copyright (c) 2026 Jaival
```

Use the canonical MIT text (the paragraph starting "Permission is hereby granted, free of charge, to any person obtaining a copy…" through "…OTHER DEALINGS IN THE SOFTWARE."). Do not add an email address.

**Verify**: `head -1 LICENSE` → `MIT License`; `grep -c 'Copyright (c) 2026 Jaival' LICENSE` → `1`; `grep -c '@' LICENSE` → `0`.

### Step 2: Check the Terraform version in `check-tools.sh`

Insert this block between the `done` that ends the first loop and the line `for tool in tflint checkov; do` (keep one blank line before and after):

```bash
# The configs need Terraform >= 1.10 (S3 backend `use_lockfile`).
if command -v terraform >/dev/null 2>&1; then
  read -r tf_major tf_minor < <(terraform version | head -1 | sed -E 's/^Terraform v([0-9]+)\.([0-9]+).*/\1 \2/')
  if [[ "${tf_major:-}" =~ ^[0-9]+$ && "${tf_minor:-}" =~ ^[0-9]+$ ]]; then
    if (( tf_major < 1 || (tf_major == 1 && tf_minor < 10) )); then
      bad "terraform ${tf_major}.${tf_minor} is too old — this repo needs 1.10 or newer"
    fi
  else
    warn "could not read the terraform version"
  fi
fi
```

**Verify**: `bash -n scripts/check-tools.sh` → exit 0; then run `./scripts/check-tools.sh; echo "exit=$?"` → no bash error text. Also test the comparison logic in isolation:
`bash -c 'tf_major=1; tf_minor=9; (( tf_major < 1 || (tf_major == 1 && tf_minor < 10) )) && echo old'` → `old`, and the same with `tf_minor=13` → prints nothing.

### Step 3: Expire old state versions on AWS

In `foundations/02-state-backend/aws/main.tf`, insert between the end of the `aws_s3_bucket_server_side_encryption_configuration` block and the comment `# Only allow HTTPS access to the state bucket.`:

```hcl
# Without this, every old version of every state file is kept (and billed) forever.
# Keep the 10 newest old versions; the GCP backend does the same with a lifecycle_rule.
resource "aws_s3_bucket_lifecycle_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    id     = "expire-old-state-versions"
    status = "Enabled"

    filter {} # applies to every object in the bucket

    noncurrent_version_expiration {
      newer_noncurrent_versions = 10
      noncurrent_days           = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  depends_on = [aws_s3_bucket_versioning.state]
}
```

**Verify**: the Format and Validate commands in the table succeed.

## Test plan

- Step 2's isolated comparison checks above (old → flagged, new → not flagged).
- Plan 007 adds mocked Terraform tests; it may assert the lifecycle rule exists.

## Done criteria

- [ ] `test -f LICENSE` and `head -1 LICENSE` is `MIT License`
- [ ] `bash -n scripts/check-tools.sh` exits 0
- [ ] `terraform fmt -check -recursive -diff` exits 0; AWS state backend validates
- [ ] `grep -c 'aws_s3_bucket_lifecycle_configuration' foundations/02-state-backend/aws/main.tf` returns `1`
- [ ] `git status --short` shows only the three in-scope files plus `plans/README.md`
- [ ] `plans/README.md` status row for 006 updated

## STOP conditions

- The text quoted in "Current state" is not present in the file (the repo has drifted).
- A step's verification fails twice after a reasonable fix attempt.
- The fix appears to require touching a file outside the in-scope list.
- Any command asks for cloud credentials or would contact a real cloud account.
- The operator has not confirmed MIT and tells you a different licence — skip step 1 and report; do steps 2–3.
- `terraform validate` rejects `filter {}` or requires different arguments in the lifecycle rule (provider schema differs from AWS provider 6.x as assumed) — report the exact error.

## Maintenance notes

- `noncurrent_days = 30` means an old version is deleted only once it is both older than 30 days *and* beyond the 10 newest. That is the recovery window for a corrupted state.
- If the owner later prefers a different licence, replace the file; nothing else references it.
