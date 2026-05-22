#!/bin/bash

DOT_FILES_DIR=$(realpath "$(dirname "$0")")

source "${DOT_FILES_DIR}/scripts/checkbox_menu.sh"
source "${DOT_FILES_DIR}/scripts/install_report.sh"

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
    echo "Installing Vundle Vim!"
    create_backup "${VUNDLE_VIM_PATH}"
    run_cmd git clone https://github.com/VundleVim/Vundle.vim.git "$VUNDLE_VIM_PATH/bundle/Vundle.vim" || { report_failure "Vundle Vim clone"; return 2; }
    run_cmd vim +PluginInstall +qall || { report_failure "Vundle Vim PluginInstall"; return 3; }
}

function installOhMyZsh() {
    echo "Installing Oh-My-Zsh!"
    create_backup "${OH_MY_ZSH_PATH}"
    run_cmd sh -c 'curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh | sh -s -- --unattended --skip-chsh' || { report_failure "Oh My Zsh install"; return 2; }
    installOhMyZsh-plugins
}

function installOhMyZsh-plugins() {
    for i in "${ZSH_PLUGIN_LIST[@]}"; do
        local repo=$(echo "$i" | cut -d";" -f1)
        local folder=$(echo "$i" | cut -d";" -f2)
        run_cmd git clone --depth=1 "$repo" "$folder" || report_failure "Oh My Zsh plugin: $repo"
    done
}

function create_config_menu() {
    local labels=()
    local types=()
    local values=()
    local selected_indexes=()
    local selected=()
    local index=0

    if command -v zsh > /dev/null; then
        labels+=("tool: Oh My Zsh")
        types+=("oh_my_zsh")
        values+=("oh_my_zsh")
        selected+=(0)
    else
        echo "Oh My Zsh is not available in the menu because zsh is not installed."
    fi

    if command -v vim > /dev/null; then
        labels+=("tool: Vundle Vim")
        types+=("vundle_vim")
        values+=("vundle_vim")
        selected+=(0)
    else
        echo "Vundle Vim is not available in the menu because vim is not installed."
    fi

    for i in "${LINK_FILES[@]}"; do
        local from=$(echo "$i" | cut -d":" -f1)
        local to=$(echo "$i" | cut -d":" -f2)
        labels+=("config: $from -> $to")
        types+=("link")
        values+=("$i")
        selected+=(0)
    done

    mapfile -t selected_indexes < <(checkbox_menu "Select config tools and files to install" "${labels[@]}")

    for index in "${selected_indexes[@]}"; do
        selected[index]=1
    done

    for ((index = 0; index < ${#labels[@]}; index++)); do
        if [ "${selected[index]}" -ne 1 ]; then
            echo "Installation of ${labels[index]} skipped!"
            continue
        fi

        case "${types[index]}" in
            oh_my_zsh)
                installOhMyZsh
                ;;
            vundle_vim)
                installVundleVim
                ;;
            link)
                install_symbolic_link "${values[index]}"
                ;;
        esac
    done
}

function install_symbolic_link() {
    local link_file="$1"
    local from=$(echo "$link_file" | cut -d":" -f1)
    local to=$(echo "$link_file" | cut -d":" -f2)

    echo "Installing $from!"
    create_backup "$to"
    run_cmd mkdir -p "$(dirname "$to")"
    echo "Creating symbolic link of $from on $to..."
    run_cmd ln -s "$from" "$to" || report_failure "symbolic link: $from -> $to"
}

function create_backup() {
    local file_or_folder="$1"
    local file_or_folder_bkp="${file_or_folder}$(date +"%Y-%m-%d-%T").bkp"
    if [ -n "${file_or_folder}" ]; then
        if [ -h "${file_or_folder}" ]; then
            run_cmd unlink "${file_or_folder}" || report_failure "unlink: ${file_or_folder}"
        elif [ -f "${file_or_folder}" ] || [ -d "${file_or_folder}" ]; then
            echo "Creating a backup to $file_or_folder in ${file_or_folder_bkp}"
            run_cmd mv "$file_or_folder" "$file_or_folder_bkp" || report_failure "backup: $file_or_folder"
        fi
    else
        echo "create_backup need a param"
    fi
}

function main() {
    create_config_menu
    echo "Copying fish_variables to fish folder..."
    run_cmd cp "${DOT_FILES_DIR}/fish/fish_variables" "${DOT_FILES_DIR}/fish/fish/fish_variables" || report_failure "copy fish_variables"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    standalone_report=0
    if [ -z "${DOTFILES_INSTALL_REPORT_FILE:-}" ]; then
        standalone_report=1
    fi
    init_install_report
    if [ "$standalone_report" = "1" ]; then
        trap 'install_report_trap_exit 130' INT
        trap 'install_report_trap_exit 143' TERM
        trap 'print_install_report; cleanup_install_report' EXIT
    fi
    main "$@"
fi
