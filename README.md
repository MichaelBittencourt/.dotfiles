# Michael Bittencourt Dotfiles

This project installs my shell, editor, terminal and development environment configuration in a new machine.

## Install

### With curl

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/MichaelBittencourt/.dotfiles/main/download.sh)"
```

### With wget

```bash
bash -c "$(wget https://raw.githubusercontent.com/MichaelBittencourt/.dotfiles/main/download.sh -O -)"
```

## Installer behavior

The installer uses interactive checkbox menus for both dependency installation and dotfile/configuration installation.

Menu controls:

- Navigation: Up/Down/Left/Right
- Toggle item: Space
- Select all: `a`
- Deselect all: `n`
- Confirm: Enter

The dependency menu can install apt packages such as shells, editors, Git, curl/wget, tmux, SSH client/server, build tools for C/C++, Erlang and other base tools. It can also install Android platform tools, the asdf version manager, and Docker Engine with the Docker Compose plugin.

Docker Engine is installed from Docker's official Ubuntu apt repository, including the apt keyring setup, repository source list, Docker Engine, Docker CLI, containerd, buildx and the Docker Compose plugin. When Docker is available, the installer also offers a Docker group configuration menu showing the command that will be executed: `sudo groupadd -f docker && sudo usermod -aG docker <home-owner>`. The target user is detected from the owner of `$HOME`. After changing group membership, the user may need to log out and back in, or run `newgrp docker`. The installer validates the new group context with `sg docker -c 'docker --version'` and `sg docker -c 'docker compose version'`.

After the main dependency menu finishes, the installer opens extra menus only when the required command is available:

- asdf languages: Rust, Node.js, Elixir, Go, Python, Java OpenJDK 26 and Kotlin.
- Cargo software: exa and bat, only when `cargo` is available and working.
- Oh My Zsh appears in the config menu only when `zsh` is available.
- Vundle Vim appears in the config menu only when `vim` is available.

The asdf language flow installs the plugin/version, sets the user default version with `asdf set -u <plugin> <version>`, runs `asdf reshim`, and then executes a basic command test for the selected language.

### Non-interactive install

Both local installer scripts support `--all` to skip the interactive checkbox menus and select every available option.

```bash
bash install_dependencies.sh --all
bash install.sh --all
```

This is useful for Docker image builds or automated setup scripts. For a full local container test without menus, run:

```bash
docker compose run --rm test-local-full --all
```

The remote test wrapper also forwards `--all` to the downloaded installer:

```bash
docker compose run --rm test-remote --all
```

Because `test-remote` downloads from the GitHub `main` branch, this command only uses the local `--all` implementation after these changes are available on `main`.

During a Docker image build, make sure the build environment provides every command the installer expects. The current development container uses a mocked `sudo` from `dev/sudo`; a custom Dockerfile should either provide `sudo`, provide an equivalent mock, or adapt the install command for root execution.

## Error log

Installation failures are summarized at the end of the process. The installer also writes command errors to a persistent log file:

```bash
$HOME/.dotfiles-install-errors.log
```

The log is reset at the start of a new local test/install wrapper run. When a command fails, the log includes the command, the real stderr shown during installation, the exit status, and the installer failure label.

Example:

```text
[2026-05-22 10:44:15] command: asdf plugin add python
error fetching plugin URL: unable to initialize index: unable to clone plugin: bash: line 1: git: command not found
[2026-05-22 10:44:15] exit status: 1
[2026-05-22 10:44:15] asdf plugin: Python
```

## Development

You can test changes inside Docker without affecting your current environment. The development image is intentionally minimal: Ubuntu with curl only. The dotfiles repository is mounted at `/root/.dotfiles`, and the container workspace is `/root`, matching the expected real install layout.

Docker and Docker Compose must be installed and working on your machine.

### Build the Docker image

```bash
docker compose build
```

If your shell still does not have access to the Docker group after installing Docker, run commands through `sg docker -c`, for example:

```bash
sg docker -c 'docker compose build'
```

### Test services

| Service | Command | What it runs |
| --- | --- | --- |
| `test` | `docker compose run --rm test` | Alias for `test-local`. |
| `test-local` | `docker compose run --rm test-local` | Runs the local `install.sh` from `/root/.dotfiles`. |
| `test-local-dependencies` | `docker compose run --rm test-local-dependencies` | Runs the local `install_dependencies.sh`. |
| `test-local-full` | `docker compose run --rm test-local-full` | Runs local dependencies first, then local configs. |
| `test-remote` | `docker compose run --rm test-remote` | Runs the remote install command from the GitHub `main` branch. |

For a full local test, use:

```bash
docker compose run --rm test-local-full
```

Or, when Docker group membership has not been applied to the current shell:

```bash
sg docker -c 'docker compose run --rm test-local-full'
```

After each local test script finishes, it opens `fish` when available; otherwise it opens `bash`.
