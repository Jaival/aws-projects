# Plan 007: Every foundations Terraform folder has credential-free `terraform test` checks that run in CI

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md` — unless a reviewer dispatched you and told you they
> maintain the index.
>
> **Drift check (run first)**: `git diff --stat 8c744d3..HEAD -- foundations .github/workflows/terraform-checks.yml CLAUDE.md`
> If any in-scope file changed since this plan was written, compare the
> "Current state" excerpts against the live code before proceeding. Earlier
> plans in `plans/README.md` deliberately edit some of the same files, so line
> numbers may have shifted: **locate text by its content, not its line
> number**. If the quoted text itself is missing or different, that is a STOP
> condition.

## Status

- **Priority**: P2
- **Effort**: M
- **Risk**: LOW
- **Depends on**: plans/001, 004, 005, 006 (asserts what they add; edits the workflow after 001)
- **Category**: tests
- **Batch**: 3 (see `plans/README.md`)
- **Planned at**: commit `8c744d3`, 2026-11-13

## Why this matters

The only automated check on the Terraform is `terraform validate`, which proves
syntax, not behaviour. Nothing has ever been deployed. Mistakes that only show
at deploy time — an Azure storage account name longer than 24 characters, a
bucket that is not private, a missing tag, outputs that differ between clouds —
are invisible. Terraform's built-in test framework can run each folder against
**mock providers**, which needs no cloud account, costs nothing, and runs in CI.

Confidence note for the executor: the test files below were written from
knowledge of the test framework (Terraform ≥ 1.11) but **have not been run**.
Expect to adjust a few assertions; the rules for what you may adjust are in step 3.

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

After plans 004–006 the six folders contain (verify by reading each `main.tf` first):

| Folder | Resources | Outputs |
|---|---|---|
| `foundations/01-hello-storage/aws` | `random_id.suffix`, `aws_s3_bucket.this` (name `${var.project}-${var.env}-hello-<6 hex>`), `aws_s3_bucket_public_access_block.this`, `aws_s3_bucket_versioning.this`, `aws_s3_bucket_server_side_encryption_configuration.this` | `bucket_name`, `bucket_url` |
| `foundations/01-hello-storage/azure` | `random_id.suffix`, `azurerm_resource_group.this`, `azurerm_storage_account.this` (name `st${var.project}${var.env}<6 hex>`), `azurerm_storage_container.this` | `bucket_name`, `bucket_url` |
| `foundations/01-hello-storage/gcp` | `random_id.suffix`, `google_storage_bucket.this`; needs variable `gcp_project_id` (no default) | `bucket_name`, `bucket_url` |
| `foundations/02-state-backend/aws` | `data.aws_caller_identity.current`, `aws_s3_bucket.state` (name `tfstate-<account id>-<region>`, **`prevent_destroy = true`**), public access block, versioning, encryption, lifecycle configuration (plan 006), `aws_s3_bucket_policy.tls_only` | `backend_config` |
| `foundations/02-state-backend/azure` | `random_id.suffix`, `azurerm_resource_group.state`, `azurerm_storage_account.state` (**`prevent_destroy = true`**), `azurerm_storage_container.state`, `data.azurerm_client_config.current` + `azurerm_role_assignment.state_blob_contributor` (plan 004) | `backend_config` |
| `foundations/02-state-backend/gcp` | `google_storage_bucket.state` (name `${var.gcp_project_id}-tfstate`, **`prevent_destroy = true`**); needs `gcp_project_id` | `backend_config` |

Variables in the hello-storage folders: `project` (regex `^[a-z0-9]{2,8}$`, default `p00`), `env` (`dev|test|prod`, default `dev`), `region`, `owner`, `autoshutdown` (bool, plan 005).

The CI `validate` job in `.github/workflows/terraform-checks.yml` ends with these steps (the job runs once per folder with `working-directory: ${{ matrix.dir }}`):

```yaml
      - name: terraform init (no backend)
        run: terraform init -backend=false -input=false
      - name: terraform validate
        run: terraform validate
```
The `discover` job finds folders with `find . -name '*.tf'`; files named `*.tftest.hcl` do **not** match that pattern, which is what we want.

**Important behaviour of `terraform test`:**
- `command = apply` with a `mock_provider` creates nothing real, but at the end of the test Terraform "destroys" the mocked resources. A resource with `prevent_destroy = true` makes that cleanup fail. Therefore: **hello-storage folders use `command = apply`; state-backend folders use `command = plan` only.**
- With `command = plan`, attributes computed by a provider are unknown and cannot be asserted. Only assert arguments written literally in the config. `override_during = plan` on an `override_data` block makes its values known during plan.
- `random_id` comes from the real `hashicorp/random` provider (not mocked); it needs no credentials.

## Commands you will need

**Terraform CLI**: run `terraform version`. You need 1.10 or newer (CI uses 1.13.x).
If the command is missing, download the Linux zip for the newest 1.13.x from
`https://releases.hashicorp.com/terraform/`, unzip it into a directory **outside
the repo** (e.g. `$HOME/bin`) and put it on `PATH`. If you cannot install it,
STOP and report. `terraform init` creates `.terraform/` folders; they are
git-ignored — leave them, never commit them.

| Purpose | Command | Expected on success |
|---|---|---|
| Run one folder's tests | `cd <folder> && terraform init -backend=false -input=false >/dev/null && terraform test` | `Success! N passed, 0 failed.` |
| Run all | `for d in foundations/*/*/; do (cd "$d" && terraform init -backend=false -input=false >/dev/null && terraform test) || echo "FAILED $d"; done` | six `Success!` lines, no `FAILED` |
| Format (also formats test files) | `terraform fmt -check -recursive -diff` | exit 0 |
| YAML parses | `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/terraform-checks.yml')); print('ok')"` | `ok` |

## Scope

**In scope**:
- `foundations/<exercise>/<cloud>/tests/main.tftest.hcl` — six new files
- `.github/workflows/terraform-checks.yml` (one added step in the `validate` job)
- `CLAUDE.md` (one added command, only if the file exists)
- `plans/README.md` (status row only)

**Out of scope** (do NOT touch):
- Any `main.tf`, `variables.tf`, `outputs.tf`. If a test fails because the **config** is wrong (e.g. a name really can exceed a limit), that is a finding: STOP and report it, do not "fix" the config and do not weaken the test.
- Removing `prevent_destroy`.
- `.terraform.lock.hcl` files.
- Other jobs in the workflow (`fmt`, `discover`, `all-checks`).

## Git workflow

- Branch: `improve/batch-3` (create it from `main` if it does not exist; if it exists, continue on it — all plans of one batch share one branch).
- One commit for this plan. Message style is conventional commits, e.g. `test: add mocked terraform tests for foundations`.
- **Commit identity is mandatory** — commit with exactly:
  `git -c user.name="Jaival" -c user.email="Jaival@users.noreply.github.com" commit -m "<message>"`
  Never use any other name or email address. Do not put URLs, session links or
  tool names in the commit message.
- Do NOT push, merge, or open a PR unless the operator explicitly instructs it.

## Steps

### Step 1: hello-storage tests (three files, `command = apply`)

Create `foundations/01-hello-storage/aws/tests/main.tftest.hcl`:

```hcl
# Runs against a mock AWS provider: no credentials, nothing is created.
mock_provider "aws" {}

run "defaults" {
  command = apply

  assert {
    condition     = can(regex("^p00-dev-hello-[0-9a-f]{6}$", aws_s3_bucket.this.bucket))
    error_message = "Bucket name must be <project>-<env>-hello-<6 hex chars>."
  }

  assert {
    condition = alltrue([
      aws_s3_bucket_public_access_block.this.block_public_acls,
      aws_s3_bucket_public_access_block.this.block_public_policy,
      aws_s3_bucket_public_access_block.this.ignore_public_acls,
      aws_s3_bucket_public_access_block.this.restrict_public_buckets,
    ])
    error_message = "All four public-access blocks must be on."
  }

  assert {
    condition     = aws_s3_bucket_versioning.this.versioning_configuration[0].status == "Enabled"
    error_message = "Versioning must be enabled."
  }

  assert {
    condition     = output.bucket_url == "s3://${output.bucket_name}"
    error_message = "bucket_url must be s3://<bucket_name>."
  }
}

run "longest_allowed_names" {
  command = apply

  variables {
    project = "abcdefgh"
    env     = "prod"
  }

  assert {
    condition     = length(aws_s3_bucket.this.bucket) <= 63
    error_message = "S3 bucket names are limited to 63 characters."
  }
}

run "rejects_invalid_project" {
  command = plan

  variables {
    project = "Bad_Name"
  }

  expect_failures = [var.project]
}

run "rejects_invalid_env" {
  command = plan

  variables {
    env = "staging"
  }

  expect_failures = [var.env]
}
```

Create `foundations/01-hello-storage/azure/tests/main.tftest.hcl` with the same four `run` blocks, adapted:
- `mock_provider "azurerm" {}`
- `defaults` asserts: `can(regex("^stp00dev[0-9a-f]{6}$", azurerm_storage_account.this.name))`; `azurerm_storage_account.this.shared_access_key_enabled == false`; `azurerm_storage_account.this.allow_nested_items_to_be_public == false`; `azurerm_storage_account.this.min_tls_version == "TLS1_2"`; `azurerm_storage_container.this.container_access_type == "private"`; `azurerm_resource_group.this.tags["autoshutdown"] == "true"`; `output.bucket_name == "${azurerm_storage_account.this.name}/hello"`.
- `longest_allowed_names` asserts: `length(azurerm_storage_account.this.name) <= 24` and `can(regex("^[a-z0-9]+$", azurerm_storage_account.this.name))` (Azure limit: 3–24 lowercase letters/digits).
- the two `rejects_*` runs unchanged.

Create `foundations/01-hello-storage/gcp/tests/main.tftest.hcl`, adapted:
- `mock_provider "google" {}`
- a file-level block so every run has the required variable:
  ```hcl
  variables {
    gcp_project_id = "test-project"
  }
  ```
- `defaults` asserts: `can(regex("^p00-dev-hello-[0-9a-f]{6}$", google_storage_bucket.this.name))`; `google_storage_bucket.this.public_access_prevention == "enforced"`; `google_storage_bucket.this.uniform_bucket_level_access == true`; `google_storage_bucket.this.location == "ASIA-SOUTH1"`; `google_storage_bucket.this.versioning[0].enabled == true`; `output.bucket_name == google_storage_bucket.this.name`.
- `longest_allowed_names` asserts `length(google_storage_bucket.this.name) <= 63`.
- the two `rejects_*` runs unchanged.

**Verify**: "Run one folder's tests" in each of the three folders → `Success! 4 passed, 0 failed.`

### Step 2: state-backend tests (three files, `command = plan` only)

Create `foundations/02-state-backend/aws/tests/main.tftest.hcl`:

```hcl
# Plan-only: the state bucket has prevent_destroy, so a mocked apply could not be cleaned up.
mock_provider "aws" {}

override_data {
  target          = data.aws_caller_identity.current
  override_during = plan
  values = {
    account_id = "123456789012"
  }
}

run "plan" {
  command = plan

  assert {
    condition     = aws_s3_bucket.state.bucket == "tfstate-123456789012-ap-south-1"
    error_message = "State bucket must be named tfstate-<account id>-<region>."
  }

  assert {
    condition = alltrue([
      aws_s3_bucket_public_access_block.state.block_public_acls,
      aws_s3_bucket_public_access_block.state.block_public_policy,
      aws_s3_bucket_public_access_block.state.ignore_public_acls,
      aws_s3_bucket_public_access_block.state.restrict_public_buckets,
    ])
    error_message = "All four public-access blocks must be on."
  }

  assert {
    condition     = aws_s3_bucket_versioning.state.versioning_configuration[0].status == "Enabled"
    error_message = "State must be versioned."
  }
}
```
(`123456789012` is AWS's documentation placeholder account number, not a real account.)

Create `foundations/02-state-backend/azure/tests/main.tftest.hcl`: `mock_provider "azurerm" {}`, one `run "plan"` with `command = plan` asserting only literal arguments: `azurerm_resource_group.state.name == "rg-tfstate"`; `azurerm_storage_account.state.account_replication_type == "ZRS"`; `azurerm_storage_account.state.shared_access_key_enabled == false`; `azurerm_storage_account.state.min_tls_version == "TLS1_2"`; `azurerm_storage_container.state.name == "tfstate"`; `azurerm_role_assignment.state_blob_contributor.role_definition_name == "Storage Blob Data Contributor"`; `azurerm_resource_group.state.tags["autoshutdown"] == "false"`.

Create `foundations/02-state-backend/gcp/tests/main.tftest.hcl`: `mock_provider "google" {}`, file-level `variables { gcp_project_id = "test-project" }`, one `run "plan"` with `command = plan` asserting: `google_storage_bucket.state.name == "test-project-tfstate"`; `google_storage_bucket.state.public_access_prevention == "enforced"`; `google_storage_bucket.state.uniform_bucket_level_access == true`; `google_storage_bucket.state.versioning[0].enabled == true`.

**Verify**: "Run one folder's tests" in each of the three folders → `Success! 1 passed, 0 failed.`

### Step 3: Make them pass — what you may and may not change

Run `terraform fmt -recursive foundations`, then "Run all". For each failure:

- **Allowed**: fix test syntax; drop an assertion that fails *only* with "unknown value" / "known only after apply" in a plan-only run (note each dropped assertion in your report); add a `mock_resource` / `override_resource` block with fixed `defaults`/`values` when a mocked computed value breaks an unrelated expression; change how an attribute is addressed (e.g. `[0]` indexing) to match the provider schema.
- **Not allowed**: changing an expected value to whatever the config happens to produce; deleting an assertion because the config violates it; editing any non-test file.
- If a hello-storage `apply` run fails during cleanup/destroy for a reason other than `prevent_destroy`, switch that file to `command = plan` and keep only literal-argument assertions; report it.

**Verify**: "Run all" → six `Success!` lines, no `FAILED`; `terraform fmt -check -recursive -diff` → exit 0.

### Step 4: Run the tests in CI

In `.github/workflows/terraform-checks.yml`, add one step at the end of the `validate` job's steps, after `terraform validate`:

```yaml
      - name: terraform test (mock providers, no cloud credentials)
        if: hashFiles(format('{0}/tests/*.tftest.hcl', matrix.dir)) != ''
        run: terraform test
```

**Verify**: YAML parse command → `ok`; `grep -c 'terraform test' .github/workflows/terraform-checks.yml` → `2`.

### Step 5: Document the command

If `CLAUDE.md` exists, add this fenced block under "Checks to run before committing", after the validate block:

````
```bash
cd <changed terraform folder> && terraform test
```
````

**Verify**: `grep -c 'terraform test' CLAUDE.md` → `1` (skip if the file does not exist).

## Test plan

The deliverable *is* the tests. Prove they can fail: temporarily change `"Enabled"` to `"Suspended"` in the assertion of `foundations/01-hello-storage/aws/tests/main.tftest.hcl`, run `terraform test` → must report a failure; then restore the file (`git checkout` or undo) and confirm it passes again.

## Done criteria

- [ ] `ls foundations/*/*/tests/main.tftest.hcl | wc -l` returns `6`
- [ ] "Run all" prints six `Success!` lines and no `FAILED`
- [ ] `terraform fmt -check -recursive -diff` exits 0
- [ ] Workflow YAML parses and contains the new step
- [ ] `git diff --stat` shows no change to any `main.tf`, `variables.tf`, `outputs.tf`, `.terraform.lock.hcl`
- [ ] `plans/README.md` status row for 007 updated, listing any assertions dropped under step 3

## STOP conditions

- The text quoted in "Current state" is not present in the file (the repo has drifted).
- A step's verification fails twice after a reasonable fix attempt.
- The fix appears to require touching a file outside the in-scope list.
- Any command asks for cloud credentials or would contact a real cloud account.
- `terraform version` is older than 1.11 and cannot be upgraded (`override_during` needs 1.11).
- A resource named in the "Current state" table does not exist (plans 004–006 have not landed) — report which.
- An assertion fails because the configuration genuinely violates it (e.g. the Azure storage account name can exceed 24 characters). This is a real bug: report it, do not hide it.
- More than a third of the assertions in any one file have to be dropped under the step 3 rules — the approach is not working for that provider; report instead of shipping a hollow test.

## Maintenance notes

- Mock tests check the *configuration*, not the cloud: they cannot catch IAM problems, quota limits or API behaviour. A real deploy by the owner is still the final proof.
- Each new `infra/<cloud>/` folder in later projects should get a `tests/main.tftest.hcl`; CI picks it up automatically.
- Deferred on purpose: a cross-cloud "parity" check comparing variable and output names of sibling `aws/azure/gcp` folders. Worth doing once project 09 adds the first real `infra/` folders.
