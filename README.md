# mandantory-cli-environment-builder
This shell script builds ansible cli environment.

This shell will
- Update cache of package manager and upgrade using package manager.
- Install `git` and `python3.x`.
- Generate `python venv` on `$HOME` directory.
  - Install `ansible` to the `venv`
