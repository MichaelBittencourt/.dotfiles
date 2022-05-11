#!/bin/bash

DOTFILES_LINK="https://github.com/MichaelBittencourt/.dotfiles.git"
DOTFILES_PATH="$HOME/.dotfiles"

function clone_dotfiles() {
    create_backup "$DOTFILES_PATH"
    git clone --depth=1 "$DOTFILES_LINK" "$DOTFILES_PATH"
}

function installDotFiles() {
    cd "$DOTFILES_PATH"
    bash "install.sh" || return 3
}

function create_backup() {
    local file_or_folder="$1"
    local file_or_folder_bkp="${file_or_folder}$(date +"%Y-%m-%d-%T").bkp"
    if [ -n "${file_or_folder}" ]; then
        if [ -h "${file_or_folder}" ]; then
            unlink ${file_or_folder}
        elif [ -f "${file_or_folder}" ] || [ -d "${file_or_folder}" ]; then
            echo "Creating a backup to $file_or_folder in ${file_or_folder_bkp}"
            mv $file_or_folder ${file_or_folder_bkp}
        fi
    else
        echo "create_backup need a param"
    fi
}

function main() {
    clone_dotfiles || echo "Error to .dontfiles!"
    installDotFiles || echo "Error to install dotfiles"
}

main
