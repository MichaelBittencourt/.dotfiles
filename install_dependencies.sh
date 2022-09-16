#!/bin/bash

ROOT_PATH="realpath $(dirname $0)"

DEPENDENCE_LIST=(vim zsh fish git curl wget tmux cargo unzip)

CARGO_DEPENDENCY_LIST=(exa bat)

ANDROID_PLATFORM_TOOLS_FILE="platform-tools-latest-linux.zip"
ANDROID_PLATFORM_TOOLS_URI="https://dl.google.com/android/repository/$ANDROID_PLATFORM_TOOLS_FILE"
ANDROID_PLATFORM_TOOLS_LOCAL_PATH="${HOME}/.platform-tools"

NVIM_FILE="nvim.appimage"
NVIM_URI="https://github.com/neovim/neovim/releases/latest/download/$NVIM_FILE"

LOCAL_BIN_PATH="${HOME}/.local/bin"

function install_apt_get_binaries() {
    echo "Updating package list of apt..."
    sudo apt-get update
    echo "Installing dependencies..."
    for item in ${DEPENDENCE_LIST[@]}
    do
        echo "Installing dependency $item"
        sudo apt-get install -y $item || echo "Error to install dependency $item"
    done
}

function install_cargo_dependencies() {
    if which cargo > /dev/null
    then
        for item in ${CARGO_DEPENDENCY_LIST[@]}
        do
            echo "Installing cargo dependency $item"
            cargo install $item || echo "Error to install cargo dependency $item"
        done
    fi
}

function install_platform_tools() {
    echo "Installing Android platform tools..."
    local currentPath=$(pwd)
    mkdir -p "$ANDROID_PLATFORM_TOOLS_LOCAL_PATH"
    cd /tmp/
    if which wget > /dev/null
    then
        wget $ANDROID_PLATFORM_TOOLS_URI
        cd $ANDROID_PLATFORM_TOOLS_LOCAL_PATH
        if unzip /tmp/platform-tools-latest-linux.zip
        then
            if mkdir -p ${LOCAL_BIN_PATH} 2> /dev/null
            then
                ln -s ${ANDROID_PLATFORM_TOOLS_LOCAL_PATH}/platform-tools/adb ${LOCAL_BIN_PATH}/adb
                ln -s ${ANDROID_PLATFORM_TOOLS_LOCAL_PATH}/platform-tools/fastboot ${LOCAL_BIN_PATH}/fastboot
                ln -s ${ANDROID_PLATFORM_TOOLS_LOCAL_PATH}/platform-tools/sqlite3 ${LOCAL_BIN_PATH}/sqlite3 
            else
                echo "Erro when create ${LOCAL_BIN_PATH}"
            fi
        else
            echo "Erro to unzip platform-tools"
        fi
    fi
    cd $currentPath
}

function install_neovim() {
    echo "Installing neovim > 0.7..."
    curl -LO $NVIM_URI
    chmod u+x nvim.appimage
    if mkdir -p ${LOCAL_BIN_PATH}
    then
        mv nvim.appimage ${LOCAL_BIN_PATH}/nvim
    else
        echo "Error to create ${LOCAL_BIN_PATH}"
        return 1
    fi
}

function configure_programs() {
    # To grant that fish shell create its configuration folder we need open the program
    if which fish > /dev/null
    then
        fish -c "echo Running echo on fish shell to test if it is alread installed and working!"
    fi
}

function main() {
    install_apt_get_binaries
    install_cargo_dependencies
    install_platform_tools
    install_neovim
    configure_programs
}

main $@

#Add default editor
#export EDITOR=vim
#chsh -s $(which fish)

#asdf install
#git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.10.2

#android studio install
#wget https://redirector.gvt1.com/edgedl/android/studio/ide-zips/2021.2.1.16/android-studio-2021.2.1.16-linux.tar.gz
#tar -xvzf /tmp/android-studio-2021.2.1.16-linux.tar.gz
#mkdir android-studio

