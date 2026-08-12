# sbx

Per-repo Supabase account switching — for humans and coding agents.

If you work in multiple repos that belong to different Supabase accounts, the
stock workflow is running `supabase login --token …` every time you switch.
That mutates **global** state: two terminals (or two coding-agent sessions) in
different repos can't use different accounts at the same time.

`sbx` fixes this with one observation: the Supabase CLI resolves credentials in
this order —

1. `SUPABASE_ACCESS_TOKEN` environment variable ← **wins, per process**
2. the token stored by `supabase login` (Keychain)
3. `~/.supabase/access-token`

So instead of switching the global login, `sbx` selects the account
*per process, based on the repo you're in*:

- **Profiles** — named personal access tokens stored in the macOS Keychain
  (never in files).
- **`.supabase-account`** — a one-line file committed in each repo, containing
  only a profile *name* (no secret).
- **A transparent `supabase` shim** — installed ahead of the real CLI in
  `PATH`. It finds the nearest `.supabase-account` above the current
  directory, exports that profile's token as `SUPABASE_ACCESS_TOKEN`, and
  execs the real binary.

Nothing else changes. You (and your agents) keep running `supabase db push`,
`supabase functions deploy`, … — the right account is chosen by *where the
command runs*. Two repos, two accounts, fully in parallel.

## Install

Requires macOS and the [Supabase CLI](https://supabase.com/docs/guides/cli).

```bash
git clone https://github.com/marxjb/sbx.git
cd sbx && ./install.sh
```

This symlinks `sbx` and the `supabase` shim into `~/.local/bin` (override with
`PREFIX=/some/bin ./install.sh`). That directory must come **before** the real
CLI in your `PATH`; the installer checks and tells you if it doesn't.

## Quickstart

```bash
# Store one profile per Supabase account (token prompted, input hidden).
# Create tokens at https://supabase.com/dashboard/account/tokens
sbx add work
sbx add client-a

# Bind each repo to its account (commit this file — it's just a name):
echo work > ~/dev/repo-one/.supabase-account
echo client-a > ~/dev/repo-two/.supabase-account

# Done. In each repo, `supabase …` now uses that repo's account:
cd ~/dev/repo-one && supabase projects list   # as `work`
cd ~/dev/repo-two && supabase projects list   # as `client-a`, simultaneously
```

Other commands:

```bash
sbx list             # stored profiles
sbx remove <name>    # delete a profile's token from the Keychain
sbx token <name>     # print a token (e.g. to feed other tools)
sbx use <name>       # old-school global switch: runs `supabase login` for you
```

## Resolution rules

For each `supabase` invocation, the shim resolves in this order:

1. If `SUPABASE_ACCESS_TOKEN` is already exported, it is left untouched —
   explicit env always wins.
2. Else, the nearest `.supabase-account` walking **up** from the current
   directory names the profile; its token comes from the Keychain.
3. Else, the shim passes through unchanged and the CLI behaves exactly as
   without sbx (global login applies).

A named-but-missing profile is a **hard error**, never a silent fall-through
to the wrong account.

`.supabase-account` format: one profile name; `#` comments and blank lines
are ignored.

## Notes for coding agents

Nothing to teach: agents run plain `supabase …` commands and inherit the
repo's account from `.supabase-account`. Parallel sessions in different repos
each get their own account with zero coordination. Agents never see or handle
tokens.

## Security

- Tokens live only in the macOS Keychain (service `sbx`, one entry per
  profile). `sbx add` keeps the token out of shell argv.
- `.supabase-account` contains a profile name only and is safe to commit.
- The Keychain layout is [go-keyring](https://github.com/zalando/go-keyring)
  compatible (service `sbx`, account = profile name), so a future Go port can
  read existing tokens without migration.

## Roadmap

- Go port for Linux/Windows keychain backends and a brew formula.

## License

[MIT](LICENSE)
