# Contributing

Issues and pull requests are welcome. Keep defaults hardware-agnostic and private.

Before submitting a change:

1. run `docker compose config --quiet`;
2. run `bash -n scripts/*.sh` and ShellCheck when available;
3. run `./scripts/validate.sh` on a representative Pi when changing deployment;
4. verify current syntax against official Frigate documentation;
5. inspect the staged diff for secrets, identifiers, addresses, and private media.

Document hardware-specific changes as opt-in examples rather than changing the
safe baseline. Do not submit recordings, snapshots, databases, or generated local
configuration.
