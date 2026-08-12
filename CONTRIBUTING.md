# Contributing

Thanks for taking an interest. supaswitch is deliberately small — a few hundred
lines of bash you can audit in one sitting — and the aim is to keep it that way.

## Running the tests

```bash
tests/run-tests.sh
```

Offline and deterministic: a fake `supabase` binary stands in for the real CLI,
and Keychain entries are namespaced by process id and removed on exit, so the
suite never touches your real profiles or the network. It must run on macOS's
system bash 3.2 — no `declare -A`, no `readarray`, no `${x^^}`.

Any change in behavior needs a test, and the test should encode what the
behavior *should* be, derived from the requirement — not whatever the new code
happens to return.

## Pull requests

**Everything lands through a pull request**, including one-line fixes. Please
don't commit to `main`.

Keep the surface minimal. Before adding a new command, flag, file, or
abstraction, look for an existing one to extend — a new mechanism needs to earn
its place against the cost of maintaining it forever. Fixes for problems that
can actually occur are welcome; speculative generality is not.

## Versioning and the changelog

A change that reaches users **must** bump `version` in `package.json` and add a
matching `CHANGELOG.md` entry **in the same commit**. A bump without an entry,
or a user-visible change without a bump, is a release-process error.

What counts as reaching users is whether the file ships, not whether it is code.
Everything in the `files` allowlist in `package.json` — including `README.md`,
`CHANGELOG.md` and `man/sbx.1` — is installed on someone's machine, so fixing
those bumps a patch. Things that never ship, like the tests and this file, do
not bump.

For a command-line tool, semver reads as:

| Bump | Meaning |
| --- | --- |
| major | the command surface, `.supabase-account` format, or Keychain layout changes |
| minor | a new command or capability |
| patch | a fix or clarification with no surface change |

Write the changelog entry for someone using the tool, not someone reading the
diff.

## The one hard constraint

Tokens are stored as macOS Keychain generic passwords with service `sbx` and
account name equal to the profile name. **That layout must not change.** It is
where every existing user's tokens already live, and it is deliberately
compatible with [go-keyring](https://github.com/zalando/go-keyring) so a future
Go port can read them without a migration. Changing the service string silently
orphans people's stored credentials.

The command is `sbx` even though the project is `supaswitch`; renaming it would
mean the same thing.

## Scope

macOS only for now, because the Keychain integration uses `security(1)`. Linux
and Windows support is intended to arrive with a Go port rather than by bolting
a second backend onto the shell version — see the roadmap in the README.
