#!/bin/bash

cd "$HOME" || exit 1
bash "$HOME/.dotfiles/install.sh"
if command -v fish > /dev/null; then
    fish
else
    bash
fi
