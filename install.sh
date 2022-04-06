#!/bin/bash

DOT_FILES_DIR=$(dirname $0)

LINK_FILES=(
    "${DOT_FILES_DIR}/bashrc:${HOME}/.bashrc"
    "${DOT_FILES_DIR}/zshrc:${HOME}/.zshrc"
    "${DOT_FILES_DIR}/p10k.zsh:${HOME}/.p10k.zsh"
    "${DOT_FILES_DIR}/oh-my-zsh:${HOME}/.oh-my-zsh"
    "${DOT_FILES_DIR}/vimrc:${HOME}/.vimrc"
    "${DOT_FILES_DIR}/vim:${HOME}/.vim"
    "${DOT_FILES_DIR}/tmux.conf:${HOME}/.tmux.conf"
    "${DOT_FILES_DIR}/clang-format:${HOME}/.clang-format"
    "${DOT_FILES_DIR}/fish:${HOME}/.config/fish"
)


function create_symbolic_links() {
    for i in ${LINK_FILES[@]}; do
        local from=$(echo $i | cut -d":" -f1)
        local to=$(echo $i | cut -d":" -f2)
        create_backup "$to"
        echo "Creating symbolic link of $from on $to..."
        ln -s "$to" "$from"
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
    cp ${DOT_FILES_DIR}/fish_variables ${DOT_FILES_DIR}/fish/fish_variables
}

main

