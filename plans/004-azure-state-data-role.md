# Plan 004: The Azure state backend grants its creator blob data access, so state migration works

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md` — unless a reviewer dispatched you and told you they
> maintain the index.
>
> **Drift check (run first)**: `git diff --stat 8c744d3..HEAD -- foundations/02-state-backend/azure foundations/README.md`
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
- **Depends on**: none (batch 2 runs after batch 1 because both edit foundations/README.md)
- **Category**: bug
- **Batch**: 2 (see `plans/README.md`)
- **Planned at**: commit `8c744d3`, 2026-11-13

## Why this matters

The Azure state storage account is created with storage keys disabled
(`shared_access_key_enabled = false`) and the generated backend block uses
`use_azuread_auth = true`. That means Terraform reads and writes state blobs
with the user's Entra ID identity — which needs a **data-plane** role
(`Storage Blob Data Contributor`). Being Owner of the subscription does not
include it. Exercise 2 never grants that role on the state account, so the very
next instruction (`terraform init -migrate-state`) is expected to fail with a 403
on Azure. The fix is to grant the role to whoever runs the bootstrap, in the
bootstrap itself.

This was found by reading the code; it has not been reproduced (nothing is deployed).

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

- `foundations/02-state-backend/azure/main.tf` — creates resource group `rg-tfstate`, the storage account and the `tfstate` container. Key lines:

```hcl
provider "azurerm" {
  features {}
  storage_use_azuread = true
}
```
```hcl
  shared_access_key_enabled       = false # pipelines authenticate with Entra ID (OIDC), not keys
```
The file currently **ends** with:
```hcl
resource "azurerm_storage_container" "state" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.state.id
  container_access_type = "private"
}
```
- `foundations/02-state-backend/azure/outputs.tf` — prints a backend block containing `use_azuread_auth     = true # Entra ID instead of storage keys`. Not changed by this plan.
- `foundations/README.md`, Exercise 2 — contains this paragraph:

```
**Then:** add the printed `backend` block to your Exercise 1 config, run `terraform init -migrate-state`,
and watch the state move into the cloud. Try running `terraform apply` from two terminals at once to
see **state locking** in action.
```

Conventions (match them): 2-space indentation, `terraform fmt` alignment of `=`, a plain-English comment above each resource explaining *why* for a learner. Exemplar: the comments in `foundations/01-hello-storage/azure/main.tf`.

## Commands you will need

**Terraform CLI**: run `terraform version`. You need 1.10 or newer (CI uses 1.13.x).
If the command is missing, download the Linux zip for the newest 1.13.x from
`https://releases.hashicorp.com/terraform/`, unzip it into a directory **outside
the repo** (e.g. `$HOME/bin`) and put it on `PATH`. If you cannot install it,
STOP and report. `terraform init` creates `.terraform/` folders; they are
git-ignored — leave them, never commit them.

| Purpose | Command | Expected on success |
|---|---|---|
| Format | `terraform fmt -check -recursive -diff` (repo root) | exit 0, no output |
| Validate | `cd foundations/02-state-backend/azure && terraform init -backend=false -input=false && terraform validate` | `Success! The configuration is valid.` |

## Scope

**In scope**:
- `foundations/02-state-backend/azure/main.tf`
- `foundations/README.md` (one inserted paragraph)
- `plans/README.md` (status row only)

**Out of scope** (do NOT touch):
- `foundations/01-hello-storage/azure/` — there the role is granted **by hand on purpose** (it teaches control plane vs data plane; see question 2 in the README). Do not automate it.
- `foundations/02-state-backend/azure/outputs.tf` and `.terraform.lock.hcl` — no new provider is needed (`azurerm` already provides both new blocks). If `terraform init` rewrites the lock file, revert that change with `git checkout -- foundations/02-state-backend/azure/.terraform.lock.hcl`.
- The AWS and GCP state backends.

## Git workflow

- Branch: `improve/batch-2` (create it from `main` if it does not exist; if it exists, continue on it — all plans of one batch share one branch).
- One commit for this plan. Message style is conventional commits, e.g. `fix: grant blob data role on the Azure state account`.
- **Commit identity is mandatory** — commit with exactly:
  `git -c user.name="Jaival" -c user.email="Jaival@users.noreply.github.com" commit -m "<message>"`
  Never use any other name or email address. Do not put URLs, session links or
  tool names in the commit message.
- Do NOT push, merge, or open a PR unless the operator explicitly instructs it.

## Steps

### Step 1: Add the role assignment

Append to the end of `foundations/02-state-backend/azure/main.tf` (one blank line before each block):

```hcl
# Who is running Terraform right now (you, signed in with `az login`).
data "azurerm_client_config" "current" {}

# Storage keys are disabled, so reading and writing state uses your Entra ID identity.
# That needs a *data-plane* role: being Owner of the subscription (control plane) is not enough.
# Project 09 adds the same role for the CI pipeline's identities.
resource "azurerm_role_assignment" "state_blob_contributor" {
  scope                = azurerm_storage_account.state.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}
```

**Verify**: both commands in the table above succeed.

### Step 2: Tell the reader about it

In `foundations/README.md`, directly after the "**Then:** …" paragraph quoted in "Current state", insert a blank line and this paragraph:

```
> **Azure note:** the state account has storage keys switched off, so Terraform reaches the state with *your* Entra ID identity. The bootstrap config gives you the `Storage Blob Data Contributor` role on that account for exactly this reason. Role assignments can take a few minutes to take effect — if `terraform init -migrate-state` answers with a 403, wait a little and run it again.
```

**Verify**: `grep -c 'Azure note:' foundations/README.md` → `1`.

## Test plan

No automated test exists yet (plan 007 adds mocked tests and will cover this resource). Verification here is `terraform validate`.

## Done criteria

- [ ] `terraform fmt -check -recursive -diff` exits 0
- [ ] `terraform validate` in `foundations/02-state-backend/azure` reports success
- [ ] `grep -c 'azurerm_role_assignment' foundations/02-state-backend/azure/main.tf` returns `1`
- [ ] `git status --short` shows only `main.tf`, `foundations/README.md`, `plans/README.md`
- [ ] `plans/README.md` status row for 004 updated

## STOP conditions

- The text quoted in "Current state" is not present in the file (the repo has drifted).
- A step's verification fails twice after a reasonable fix attempt.
- The fix appears to require touching a file outside the in-scope list.
- Any command asks for cloud credentials or would contact a real cloud account.
- `terraform validate` rejects `role_definition_name`, `principal_id` or `object_id` (would mean the provider's schema differs from azurerm 4.x as assumed).

## Maintenance notes

- Creating a role assignment requires the user to be Owner or User Access Administrator on the subscription. True for a personal subscription; in a company tenant it may not be — then the role has to be requested.
- Reviewer: the role is scoped to the single storage account, not the resource group or subscription. Keep it that way.
- Project 09 must grant the same role to its plan/deploy identities.
