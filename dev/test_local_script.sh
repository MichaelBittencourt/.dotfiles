#!/bin/bash

source "$HOME/.dotfiles/scripts/install_report.sh"
reset_install_report
trap 'install_report_trap_exit 130' INT
trap 'install_report_trap_exit 143' TERM
trap 'install_report_trap_exit $?' EXIT

cd "$HOME" || exit 1
bash "$HOME/.dotfiles/install.sh" "$@" || report_failure "install.sh failed"
trap - EXIT INT TERM
print_install_report
cleanup_install_report
if command -v fish > /dev/null; then
    fish
else
    bash
fi
