#!/bin/bash

DOT_FILES_DIR=$(realpath $(dirname $0))

LINK_FILES=(
    "${DOT_FILES_DIR}/bash/bashrc:${HOME}/.bashrc"
    "${DOT_FILES_DIR}/zsh/zshrc:${HOME}/.zshrc"
    "${DOT_FILES_DIR}/zsh/p10k.zsh:${HOME}/.p10k.zsh"
    "${DOT_FILES_DIR}/vim/vimrc:${HOME}/.vimrc"
    "${DOT_FILES_DIR}/tmux/tmux.conf:${HOME}/.tmux.conf"
    "${DOT_FILES_DIR}/clang/clang-format:${HOME}/.clang-format"
    "${DOT_FILES_DIR}/fish/fish:${HOME}/.config/fish"
    "${DOT_FILES_DIR}/lvim/config.lua:${HOME}/.config/lvim/config.lua"
    "${DOT_FILES_DIR}/i3/config:${HOME}/.config/i3/config"
    "${DOT_FILES_DIR}/xprofile/xprofile:${HOME}/.xprofile"
)

OH_MY_ZSH_PATH="${HOME}/.oh-my-zsh"
VUNDLE_VIM_PATH="${HOME}/.vim"

ZSH_PLUGIN_LIST=(
    "https://github.com/zsh-users/zsh-autosuggestions;${OH_MY_ZSH_PATH}/custom/plugins/zsh-autosuggestions"
    "https://github.com/romkatv/powerlevel10k.git;${OH_MY_ZSH_PATH}/custom/themes/powerlevel10k"
)

function installVundleVim() {
    read -r -p "Install Vundle vim? [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY])
            echo "Installing Vundle Vim!"
            create_backup "${VUNDLE_VIM_PATH}"
            git clone https://github.com/VundleVim/Vundle.vim.git "$VUNDLE_VIM_PATH/bundle/Vundle.vim" || return 2
            vim +PluginInstall +qall || return 3
            ;;
        *)
            echo "Installation of Vundle Vim skipped!"
            ;;
    esac
}

function installOhMyZsh() {
    read -r -p "Install Oh-My-Zsh? [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY])
            echo "Installing Oh-My-Zsh!"
            create_backup "${OH_MY_ZSH_PATH}"
            sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh) --unattended --skip-chsh" || return 2
            installOhMyZsh-plugins
            ;;
        *)
            echo "Installation of Oh-My-Zsh skipped!"
            ;;
    esac
}

function installOhMyZsh-plugins() {
    for i in ${ZSH_PLUGIN_LIST[@]}; do
        local repo=$(echo $i | cut -d";" -f1)
        local folder=$(echo $i | cut -d";" -f2)
        git clone --depth=1 "$repo" "$folder"
    done
}

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
    installOhMyZsh || echo "Error to install Oh-My-Zsh!"
    installVundleVim || echo "Error to install Vundle vim!"
    create_symbolic_links
    echo "Copying fish_variables to fish folder..."
    cp ${DOT_FILES_DIR}/fish/fish_variables ${DOT_FILES_DIR}/fish/fish/fish_variables
}

main

