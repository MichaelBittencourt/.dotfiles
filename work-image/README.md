# Ubuntu Work Image

This folder builds an Ubuntu image with the dotfiles installer executed during the image build.

Build the image:

```bash
docker compose build
```

Start an interactive shell:

```bash
docker compose run --rm ubuntu-work
```

Persistent files should be stored in `/workspace`. That path is mapped to the local `work-image/workspace` folder, so the same files are available both inside and outside the container.

The home directory is not mounted as a volume because mounting `/root` would hide the dotfiles and tools installed into the image during build.
