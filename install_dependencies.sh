#!/bin/bash

ROOT_PATH=$(realpath "$(dirname "$0")")

source "${ROOT_PATH}/scripts/checkbox_menu.sh"

DEPENDENCE_LIST=(bash vim neovim zsh fish git curl wget tmux unzip tar build-essential gcc g++ gdb make cmake pkg-config erlang)

CARGO_SOFTWARE_LIST=(exa bat)

ANDROID_PLATFORM_TOOLS_FILE="platform-tools-latest-linux.zip"
ANDROID_PLATFORM_TOOLS_URI="https://dl.google.com/android/repository/$ANDROID_PLATFORM_TOOLS_FILE"
ANDROID_PLATFORM_TOOLS_LOCAL_PATH="${HOME}/.platform-tools"

LOCAL_BIN_PATH="${HOME}/.local/bin"
CARGO_BIN_PATH="${HOME}/.cargo/bin"
ASDF_DATA_DIR="${ASDF_DATA_DIR:-${HOME}/.asdf}"
PATH="${LOCAL_BIN_PATH}:${CARGO_BIN_PATH}:${ASDF_DATA_DIR}/shims:${PATH}"

ASDF_VERSION="v0.19.0"
ASDF_RELEASE_BASE_URI="https://github.com/asdf-vm/asdf/releases/download/${ASDF_VERSION}"

INSTALL_FAILURES=()

function print_command() {
    printf '+ '
    printf '%q ' "$@"
    printf '\n'
}

function run_cmd() {
    print_command "$@"
    "$@"
}

function report_failure() {
    INSTALL_FAILURES+=("$1")
    echo "Error: $1"
}

function print_install_report() {
    echo ""
    echo "Installation report"
    echo "==================="

    if [ "${#INSTALL_FAILURES[@]}" -eq 0 ]; then
        echo "All selected items were installed successfully."
        return 0
    fi

    echo "The following items were not installed successfully:"
    local item=""
    for item in "${INSTALL_FAILURES[@]}"; do
        echo "- $item"
    done
}

function install_apt_get_binaries() {
    local dependencies=("$@")

    if [ "${#dependencies[@]}" -eq 0 ]; then
        echo "No apt dependencies selected."
        return 0
    fi

    echo "Updating package list of apt..."
    run_cmd sudo apt-get update || report_failure "apt update"
    echo "Installing dependencies..."
    for item in "${dependencies[@]}"
    do
        echo "Installing dependency $item"
        run_cmd sudo env DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install -y "$item" || report_failure "apt dependency: $item"
    done
}

function find_cargo_binary() {
    local binary_name="$1"
    local rust_install_path=""

    if command -v asdf > /dev/null; then
        rust_install_path=$(asdf where rust 2> /dev/null || true)
        if [ -n "$rust_install_path" ] && [ -x "${rust_install_path}/bin/${binary_name}" ]; then
            echo "${rust_install_path}/bin/${binary_name}"
            return 0
        fi
    fi

    if [ -x "${CARGO_BIN_PATH}/${binary_name}" ]; then
        echo "${CARGO_BIN_PATH}/${binary_name}"
        return 0
    fi

    command -v "$binary_name" || true
}

function link_cargo_binary() {
    local binary_name="$1"
    local binary_path=""

    binary_path=$(find_cargo_binary "$binary_name")
    if [ -z "$binary_path" ]; then
        report_failure "cargo software binary not found after install: $binary_name"
        return 1
    fi

    run_cmd mkdir -p "${LOCAL_BIN_PATH}"
    run_cmd ln -sf "$binary_path" "${LOCAL_BIN_PATH}/$binary_name" || {
        report_failure "symbolic link for cargo software: $binary_name"
        return 1
    }
    echo "Created symbolic link ${LOCAL_BIN_PATH}/$binary_name -> $binary_path"
}

function install_cargo_softwares() {
    local labels=()
    local selected_indexes=()
    local selected=()
    local item=""
    local index=0

    if ! command -v cargo > /dev/null; then
        echo "Cargo is not available. Cargo softwares skipped."
        return 0
    fi

    if ! run_cmd cargo --version; then
        report_failure "cargo availability"
        echo "Cargo softwares skipped because cargo is not usable."
        return 0
    fi

    for item in "${CARGO_SOFTWARE_LIST[@]}"; do
        labels+=("cargo: $item")
        selected+=(0)
    done

    mapfile -t selected_indexes < <(checkbox_menu "Select cargo softwares to install" "${labels[@]}")

    for index in "${selected_indexes[@]}"; do
        selected[index]=1
    done

    for ((index = 0; index < ${#CARGO_SOFTWARE_LIST[@]}; index++)); do
        item="${CARGO_SOFTWARE_LIST[index]}"
        if [ "${selected[index]}" -ne 1 ]; then
            echo "Installation of cargo: $item skipped!"
            continue
        fi

        echo "Installing cargo software $item"
        if run_cmd cargo install "$item"; then
            link_cargo_binary "$item"
        else
            report_failure "cargo software: $item"
        fi
    done
}

function install_platform_tools() {
    echo "Installing Android platform tools..."
    local currentPath=$(pwd)
    run_cmd mkdir -p "$ANDROID_PLATFORM_TOOLS_LOCAL_PATH"
    cd /tmp/ || return 1
    if which wget > /dev/null
    then
        run_cmd wget -O "/tmp/${ANDROID_PLATFORM_TOOLS_FILE}" "$ANDROID_PLATFORM_TOOLS_URI" || {
            report_failure "Android platform tools download"
            cd "$currentPath" || return 1
            return 1
        }
        cd "$ANDROID_PLATFORM_TOOLS_LOCAL_PATH" || {
            report_failure "Android platform tools directory"
            cd "$currentPath" || return 1
            return 1
        }
        if run_cmd unzip -o "/tmp/${ANDROID_PLATFORM_TOOLS_FILE}"
        then
            if run_cmd mkdir -p "${LOCAL_BIN_PATH}" 2> /dev/null
            then
                run_cmd ln -sf "${ANDROID_PLATFORM_TOOLS_LOCAL_PATH}/platform-tools/adb" "${LOCAL_BIN_PATH}/adb" || report_failure "symbolic link: adb"
                run_cmd ln -sf "${ANDROID_PLATFORM_TOOLS_LOCAL_PATH}/platform-tools/fastboot" "${LOCAL_BIN_PATH}/fastboot" || report_failure "symbolic link: fastboot"
                run_cmd ln -sf "${ANDROID_PLATFORM_TOOLS_LOCAL_PATH}/platform-tools/sqlite3" "${LOCAL_BIN_PATH}/sqlite3" || report_failure "symbolic link: sqlite3"
            else
                report_failure "create ${LOCAL_BIN_PATH} for Android platform tools"
            fi
        else
            report_failure "unzip Android platform tools"
        fi
    fi
    cd "$currentPath" || return 1
}

function get_asdf_os() {
    case "$(uname -s)" in
        Linux)
            echo "linux"
            ;;
        Darwin)
            echo "darwin"
            ;;
        *)
            echo "Unsupported OS for asdf: $(uname -s)" >&2
            return 1
            ;;
    esac
}

function get_asdf_arch() {
    case "$(uname -m)" in
        x86_64|amd64)
            echo "amd64"
            ;;
        aarch64|arm64)
            echo "arm64"
            ;;
        i386|i686)
            echo "386"
            ;;
        *)
            echo "Unsupported architecture for asdf: $(uname -m)" >&2
            return 1
            ;;
    esac
}

function install_asdf() {
    local os=""
    local arch=""
    local archive=""
    local uri=""
    local temp_dir=""

    os=$(get_asdf_os) || return 1
    arch=$(get_asdf_arch) || return 1
    archive="asdf-${ASDF_VERSION}-${os}-${arch}.tar.gz"
    uri="${ASDF_RELEASE_BASE_URI}/${archive}"
    temp_dir=$(mktemp -d)

    echo "Installing asdf ${ASDF_VERSION}..."
    run_cmd mkdir -p "${LOCAL_BIN_PATH}"
    run_cmd curl -fsSL "$uri" -o "${temp_dir}/${archive}" || {
        report_failure "asdf download"
        run_cmd rm -rf "$temp_dir"
        return 1
    }
    run_cmd tar -xzf "${temp_dir}/${archive}" -C "$temp_dir" || {
        report_failure "asdf archive extraction"
        run_cmd rm -rf "$temp_dir"
        return 1
    }
    run_cmd mv -f "${temp_dir}/asdf" "${LOCAL_BIN_PATH}/asdf" || {
        report_failure "install asdf binary"
        run_cmd rm -rf "$temp_dir"
        return 1
    }
    run_cmd chmod u+x "${LOCAL_BIN_PATH}/asdf" || report_failure "chmod asdf binary"
    run_cmd rm -rf "$temp_dir"
    run_cmd "${LOCAL_BIN_PATH}/asdf" version || report_failure "asdf version check"
}

function asdf_plugin_installed() {
    local plugin="$1"

    asdf plugin list | grep -qx "$plugin"
}

function install_asdf_language() {
    local plugin="$1"
    local label="$2"
    local version="$3"

    echo "Installing asdf plugin and version for $label..."
    if ! run_cmd asdf plugin add "$plugin"; then
        echo "+ asdf plugin list | grep -qx $plugin"
        if asdf_plugin_installed "$plugin"; then
            echo "asdf plugin $plugin already exists. Continuing..."
        else
            report_failure "asdf plugin: $label"
            return 1
        fi
    fi
    run_cmd asdf install "$plugin" "$version" || {
        report_failure "asdf language: $label $version"
        return 1
    }
    run_cmd asdf set -u "$plugin" "$version" || report_failure "asdf default version: $label"
    run_cmd asdf reshim "$plugin" || report_failure "asdf reshim: $label"
}

function test_asdf_language() {
    local plugin="$1"
    local label="$2"

    echo "Testing $label installation..."
    case "$plugin" in
        rust)
            run_cmd rustc --version || report_failure "test Rust rustc"
            run_cmd cargo --version || report_failure "test Rust cargo"
            ;;
        nodejs)
            run_cmd node --version || report_failure "test Node.js node"
            run_cmd npm --version || report_failure "test Node.js npm"
            ;;
        elixir)
            run_cmd elixir --version || report_failure "test Elixir"
            run_cmd mix --version || report_failure "test Elixir mix"
            ;;
        kotlin)
            run_cmd kotlin -version || report_failure "test Kotlin"
            ;;
        golang)
            run_cmd go version || report_failure "test Go"
            ;;
        python)
            run_cmd python --version || report_failure "test Python"
            ;;
        java)
            run_cmd java -version || report_failure "test Java"
            run_cmd javac -version || report_failure "test Java javac"
            ;;
    esac
}

function install_asdf_languages_menu() {
    local labels=("Rust" "Node.js" "Elixir" "Go" "Python" "Java OpenJDK 26" "Kotlin")
    local plugins=("rust" "nodejs" "elixir" "golang" "python" "java" "kotlin")
    local versions=("latest" "latest" "main" "latest" "latest" "openjdk-26" "latest")
    local selected_indexes=()
    local selected=()
    local index=0

    if ! command -v asdf > /dev/null; then
        echo "asdf is not available. Language installation skipped."
        return 0
    fi

    for ((index = 0; index < ${#labels[@]}; index++)); do
        selected+=(0)
    done

    mapfile -t selected_indexes < <(checkbox_menu "Select asdf languages to install" "${labels[@]}")

    for index in "${selected_indexes[@]}"; do
        selected[index]=1
    done

    for ((index = 0; index < ${#labels[@]}; index++)); do
        if [ "${selected[index]}" -ne 1 ]; then
            echo "Installation of ${labels[index]} skipped!"
            continue
        fi

        install_asdf_language "${plugins[index]}" "${labels[index]}" "${versions[index]}"
        test_asdf_language "${plugins[index]}" "${labels[index]}"
    done

    run_cmd asdf reshim || true
}

function configure_programs() {
    # To grant that fish shell create its configuration folder we need open the program
    if which fish > /dev/null
    then
        run_cmd fish -c "echo Running echo on fish shell to test if it is alread installed and working!"
    fi
}

function main() {
    local labels=()
    local types=()
    local values=()
    local selected_apt=()
    local selected_tools=()
    local selected_indexes=()
    local selected=()
    local index=0

    for item in "${DEPENDENCE_LIST[@]}"; do
        labels+=("apt: $item")
        types+=("apt")
        values+=("$item")
        selected+=(0)
    done

    labels+=("tool: Android platform tools")
    types+=("platform_tools")
    values+=("platform_tools")
    selected+=(0)

    labels+=("tool: asdf version manager")
    types+=("asdf")
    values+=("asdf")
    selected+=(0)

    labels+=("setup: Configure installed programs")
    types+=("configure_programs")
    values+=("configure_programs")
    selected+=(0)

    mapfile -t selected_indexes < <(checkbox_menu "Select dependencies to install" "${labels[@]}")

    for index in "${selected_indexes[@]}"; do
        selected[index]=1
    done

    for ((index = 0; index < ${#labels[@]}; index++)); do
        if [ "${selected[index]}" -ne 1 ]; then
            echo "Installation of ${labels[index]} skipped!"
            continue
        fi

        case "${types[index]}" in
            apt)
                selected_apt+=("${values[index]}")
                ;;
            platform_tools|asdf|configure_programs)
                selected_tools+=("${types[index]}")
                ;;
        esac
    done

    install_apt_get_binaries "${selected_apt[@]}"

    for item in "${selected_tools[@]}"; do
        case "$item" in
            platform_tools)
                install_platform_tools
                ;;
            asdf)
                install_asdf
                ;;
            configure_programs)
                configure_programs
                ;;
        esac
    done

    install_asdf_languages_menu
    install_cargo_softwares
    print_install_report
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi

#Add default editor
#export EDITOR=vim
#chsh -s $(which fish)

#android studio install
#wget https://redirector.gvt1.com/edgedl/android/studio/ide-zips/2021.2.1.16/android-studio-2021.2.1.16-linux.tar.gz
#tar -xvzf /tmp/android-studio-2021.2.1.16-linux.tar.gz
#mkdir android-studio
