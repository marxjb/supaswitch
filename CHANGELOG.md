# Changelog

All notable changes to supaswitch are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Since `sbx` is a command-line tool, "breaking" means a change to the command
surface, the `.supabase-account` format, or the Keychain layout — the last of
which existing users' stored tokens depend on.

## [1.0.0] - 2026-08-12

Initial release.

### Added

- `sbx add`, `list`, `remove`, `token` and `use` for managing named Supabase
  personal access tokens, stored in the macOS Keychain (service `sbx`, account
  = profile name) and never written to disk in plain text.
- A transparent `supabase` shim that resolves the nearest `.supabase-account`
  file upward from the working directory and exports that profile's token as
  `SUPABASE_ACCESS_TOKEN`, so repositories select their account by location and
  parallel sessions never interfere.
- `sbx install [dir]` to symlink the command, the shim and the manual page,
  refusing to replace anything it does not already own.
- `man sbx`, installed where `man(1)` looks without any `MANPATH` setup.

[1.0.0]: https://github.com/marxjb/supaswitch/releases/tag/v1.0.0
