# sbx — agent instructions

`sbx` is a small bash CLI that gives the Supabase CLI per-repo account selection:
named profiles stored in the macOS Keychain plus a transparent `supabase` shim
that exports `SUPABASE_ACCESS_TOKEN` based on a committed `.supabase-account`
file. Keep the surface minimal — it's a shell tool meant to be auditable in one
sitting.

Hard constraint: the Keychain layout must stay compatible with `go-keyring`
(service `sbx`, account = profile name) so a future Go port can read existing
tokens without migration.

Before merging any change, run `tests/run-tests.sh` (offline, bash 3.2
compatible) — it must stay green, and behavior changes need a test.

## Work Tracking (GitHub Issues + Project)

Tracked work lives in GitHub, not just session context.

- **Board:** "sbx" (Projects v2, owner `marxjb`, project #10), linked to
  `marxjb/sbx`. One **Status** field: `Todo / In Progress / Done`.
- **The issue is the work item; its body holds the plan** (template:
  `.github/ISSUE_TEMPLATE/work-item.md`). The issue body is the source of
  truth — keep it updated.
- **Status lifecycle:** Todo = accepted, not started. In Progress = a session
  is actively on it. Done = merged to main.
- **Multi-PR work → sub-issues** under the parent. `Part of #<parent>` keeps
  the parent open; `Fixes #<sub-issue>` closes a sub-issue on merge.
- **Use the `track-work` skill** to create and update tracked items. Skip
  tracking only for trivial one-off edits.
