#!/bin/bash

curl -fsSL https://raw.githubusercontent.com/MichaelBittencourt/.dotfiles/main/download.sh | bash -s -- "$@"
if command -v fish > /dev/null; then
    fish
else
    bash
fi
