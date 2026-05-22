#!/bin/bash

DOTFILES_INSTALL_REPORT_FILE="${DOTFILES_INSTALL_REPORT_FILE:-}"
DOTFILES_INSTALL_REPORT_OWNED="${DOTFILES_INSTALL_REPORT_OWNED:-0}"
DOTFILES_INSTALL_REPORT_OWNER_PID="${DOTFILES_INSTALL_REPORT_OWNER_PID:-}"
DOTFILES_INSTALL_ERROR_LOG_FILE="${DOTFILES_INSTALL_ERROR_LOG_FILE:-${HOME}/.dotfiles-install-errors.log}"
export DOTFILES_INSTALL_REPORT_FILE DOTFILES_INSTALL_REPORT_OWNED DOTFILES_INSTALL_REPORT_OWNER_PID DOTFILES_INSTALL_ERROR_LOG_FILE

function init_install_report() {
    if [ -z "$DOTFILES_INSTALL_REPORT_FILE" ]; then
        DOTFILES_INSTALL_REPORT_FILE=$(mktemp)
        DOTFILES_INSTALL_REPORT_OWNED=1
        DOTFILES_INSTALL_REPORT_OWNER_PID=$$
        : > "$DOTFILES_INSTALL_REPORT_FILE"
    fi
    export DOTFILES_INSTALL_REPORT_FILE DOTFILES_INSTALL_REPORT_OWNED DOTFILES_INSTALL_REPORT_OWNER_PID DOTFILES_INSTALL_ERROR_LOG_FILE
}

function reset_install_report() {
    init_install_report
    : > "$DOTFILES_INSTALL_REPORT_FILE"
    : > "$DOTFILES_INSTALL_ERROR_LOG_FILE"
    export DOTFILES_INSTALL_REPORT_FILE DOTFILES_INSTALL_REPORT_OWNED DOTFILES_INSTALL_REPORT_OWNER_PID DOTFILES_INSTALL_ERROR_LOG_FILE
}

function print_command() {
    printf '+ '
    printf '%q ' "$@"
    printf '\n'
}

function append_error_log_header() {
    init_install_report
    {
        printf '\n[%s] command: ' "$(date '+%Y-%m-%d %H:%M:%S')"
        printf '%q ' "$@"
        printf '\n'
    } >> "$DOTFILES_INSTALL_ERROR_LOG_FILE"
}

function run_cmd() {
    local status=0
    local temp_dir=""
    local stderr_pipe=""
    local stderr_file=""
    local tee_pid=""

    print_command "$@"

    temp_dir=$(mktemp -d)
    stderr_pipe="${temp_dir}/stderr"
    stderr_file="${temp_dir}/stderr.log"
    mkfifo "$stderr_pipe"
    tee "$stderr_file" < "$stderr_pipe" >&2 &
    tee_pid=$!

    "$@" 2> "$stderr_pipe"
    status=$?

    wait "$tee_pid"

    if [ -s "$stderr_file" ] || [ "$status" -ne 0 ]; then
        append_error_log_header "$@"
        cat "$stderr_file" >> "$DOTFILES_INSTALL_ERROR_LOG_FILE"
        if [ "$status" -ne 0 ]; then
            printf '[%s] exit status: %s
' "$(date '+%Y-%m-%d %H:%M:%S')" "$status" >> "$DOTFILES_INSTALL_ERROR_LOG_FILE"
        fi
    fi

    rm -rf "$temp_dir"
    return "$status"
}

function report_failure() {
    init_install_report
    if ! printf '%s\n' "$1" >> "$DOTFILES_INSTALL_REPORT_FILE"; then
        echo "Error: could not write installation report to $DOTFILES_INSTALL_REPORT_FILE"
    fi
    if ! printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >> "$DOTFILES_INSTALL_ERROR_LOG_FILE"; then
        echo "Error: could not write installation error log to $DOTFILES_INSTALL_ERROR_LOG_FILE"
    fi
    echo "Error: $1"
}

function print_install_report() {
    init_install_report
    echo ""
    echo "Installation report"
    echo "==================="

    if [ ! -s "$DOTFILES_INSTALL_REPORT_FILE" ]; then
        if [ -s "$DOTFILES_INSTALL_ERROR_LOG_FILE" ]; then
            echo "The following errors were recorded in $DOTFILES_INSTALL_ERROR_LOG_FILE:"
            while IFS= read -r item; do
                [ -n "$item" ] && echo "- $item"
            done < "$DOTFILES_INSTALL_ERROR_LOG_FILE"
            return 0
        fi

        echo "All selected items were installed successfully."
        echo "Error log: $DOTFILES_INSTALL_ERROR_LOG_FILE"
        return 0
    fi

    echo "The following items were not installed successfully:"
    while IFS= read -r item; do
        [ -n "$item" ] && echo "- $item"
    done < "$DOTFILES_INSTALL_REPORT_FILE"
    echo "Error log: $DOTFILES_INSTALL_ERROR_LOG_FILE"
}

function cleanup_install_report() {
    if [ "$DOTFILES_INSTALL_REPORT_OWNED" = "1" ] && [ "$DOTFILES_INSTALL_REPORT_OWNER_PID" = "$$" ] && [ -n "$DOTFILES_INSTALL_REPORT_FILE" ]; then
        rm -f "$DOTFILES_INSTALL_REPORT_FILE"
    fi
}

function install_report_trap_exit() {
    local status="$1"
    printf '[H[J[?25h'
    print_install_report
    cleanup_install_report
    exit "$status"
}
