#!/bin/bash

bash -c "$(curl -fsSL https://raw.githubusercontent.com/MichaelBittencourt/.dotfiles/main/download.sh)"
if command -v fish > /dev/null; then
    fish
else
    bash
fi
