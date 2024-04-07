# mandantory-cli-environment-builder
This shell script installs `git` and builds ansible cli environment.

This shell will
- Update cache of package manager and upgrade using package manager.
- Install `git` and `python3.x`.
- Generate `python venv` on `$HOME` directory.
  - Install `ansible` to the `venv`

## Target OS
This shell script is available for these OS.

|OS|OS version|python version|
|:---:|:---:|:---:|
|Almalinux|8.9|3.11|
|Almalinux|9.3|3.11|
|Rockylinux|8.9|3.11|
|Rockylinux|9.3|3.11|
|Debian|bullseye|3.9|
|Debian|bookworm|3.11|
|Ubuntu|focal|3.9|
|Ubuntu|jammy|3.11|
|Ubuntu|mantic|3.11|
|Ubuntu|noble|3.11|

## How to use
```sh
$ curl https://raw.githubusercontent.com/masa-orca/mandantory-cli-environment-builder/main/environment_builder.sh -o environment_builder.sh
$ sh ./environment_builder.sh
```
