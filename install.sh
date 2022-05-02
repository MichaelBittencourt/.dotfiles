#!/bin/bash

DOT_FILES_DIR=$(realpath $(dirname $0))

LINK_FILES=(
    "${DOT_FILES_DIR}/bash/bashrc:${HOME}/.bashrc"
    "${DOT_FILES_DIR}/zsh/zshrc:${HOME}/.zshrc"
    "${DOT_FILES_DIR}/zsh/p10k.zsh:${HOME}/.p10k.zsh"
    "${DOT_FILES_DIR}/zsh/oh-my-zsh:${HOME}/.oh-my-zsh"
    "${DOT_FILES_DIR}/vim/vimrc:${HOME}/.vimrc"
    "${DOT_FILES_DIR}/vim/vim:${HOME}/.vim"
    "${DOT_FILES_DIR}/tmux/tmux.conf:${HOME}/.tmux.conf"
    "${DOT_FILES_DIR}/clang/clang-format:${HOME}/.clang-format"
    "${DOT_FILES_DIR}/fish/fish:${HOME}/.config/fish"
    "${DOT_FILES_DIR}/lvim/config.lua:${HOME}/.config/lvim/config.lua"
    "${DOT_FILES_DIR}/i3/config:${HOME}/.config/i3/config"
    "${DOT_FILES_DIR}/xprofile/xprofile:${HOME}/.xprofile"
)


function create_symbolic_links() {
    for i in ${LINK_FILES[@]}; do
        local from=$(echo $i | cut -d":" -f1)
        local to=$(echo $i | cut -d":" -f2)
        local response=""
        read -r -p "Install $from to $to? [y/N] " response
        case "$response" in
            [yY][eE][sS]|[yY])
                echo "Installing $from!"
                create_backup "$to"
                echo "Creating symbolic link of $from on $to..."
                ln -s "$from" "$to"
                #ln -s $(pwd)/fish ~/.config/fish
                ;;
            *)
                echo "Installation of $from skipped!"
                ;;
        esac
    done
}

function create_backup() {
    local file_or_folder="$1"
    if [ -n "${file_or_folder}" ]; then 
        if [ -h "${file_or_folder}" ]; then
            unlink ${file_or_folder}
        elif [ -f "${file_or_folder}" ] || [ -d "${file_or_folder}" ]; then
            echo "Creating a backup to $file_or_folder in ${file_or_folder}.bkp"
            mv $file_or_folder ${file_or_folder}.bkp
        fi
    else 
        echo "create_backup need a param"
    fi
}

function main() {
    create_symbolic_links
    echo "Copying fish_variables to fish folder..."
    cp ${DOT_FILES_DIR}/fish/fish_variables ${DOT_FILES_DIR}/fish/fish/fish_variables
}

main

