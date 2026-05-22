#!/bin/bash

function checkbox_menu() {
    local title="$1"
    shift
    local items=("$@")
    local selected=()
    local current=0
    local previous=0
    local key=""
    local key_rest=""
    local index=0
    local start_row=0
    local term_cols=80
    local max_item_len=0
    local cell_width=0
    local column_count=1
    local row_count=0
    local term_rows=24
    local menu_height=0
    local menu_top=1
    local reset=$'\033[0m'
    local bold=$'\033[1m'
    local dim=$'\033[2m'
    local cyan=$'\033[36m'
    local green=$'\033[32m'
    local yellow=$'\033[33m'
    local gray=$'\033[90m'
    local previous_int_trap=""
    local previous_term_trap=""

    if [ "${#items[@]}" -eq 0 ]; then
        return 0
    fi

    for ((index = 0; index < ${#items[@]}; index++)); do
        selected[index]=1
        if [ "${#items[index]}" -gt "$max_item_len" ]; then
            max_item_len="${#items[index]}"
        fi
    done

    if [ ! -t 0 ] || [ ! -r /dev/tty ]; then
        for ((index = 0; index < ${#selected[@]}; index++)); do
            if [ "${selected[index]}" -eq 1 ]; then
                printf '%s
' "$index"
            fi
        done
        return 0
    fi

    term_cols=$(tput cols 2> /dev/null || echo 80)
    if ! [[ "$term_cols" =~ ^[0-9]+$ ]]; then
        term_cols=80
    fi

    cell_width=$((max_item_len + 8))
    if [ "$cell_width" -lt 24 ]; then
        cell_width=24
    fi
    column_count=$((term_cols / cell_width))
    if [ "$column_count" -lt 1 ]; then
        column_count=1
    fi
    if [ "$column_count" -gt "${#items[@]}" ]; then
        column_count="${#items[@]}"
    fi
    row_count=$(( (${#items[@]} + column_count - 1) / column_count ))
    term_rows=$(tput lines 2> /dev/null || echo 24)
    if ! [[ "$term_rows" =~ ^[0-9]+$ ]]; then
        term_rows=24
    fi
    menu_height=$((8 + row_count))
    if [ "$menu_height" -gt "$term_rows" ]; then
        menu_height="$term_rows"
    fi
    menu_top=$((term_rows - menu_height + 1))
    if [ "$menu_top" -lt 1 ]; then
        menu_top=1
    fi
    start_row=$((menu_top + 8))

    function _checkbox_position_for_index() {
        local line_index="$1"
        local row=$((line_index % row_count))
        local column=$((line_index / row_count))
        local screen_row=$((start_row + row))
        local screen_col=$((1 + column * cell_width))

        printf '%s %s
' "$screen_row" "$screen_col"
    }

    function _checkbox_cleanup() {
        printf '\033[H\033[J\033[?25h' > /dev/tty
    }

    function _checkbox_restore_traps() {
        if [ -n "$previous_int_trap" ]; then
            eval "$previous_int_trap"
        else
            trap - INT
        fi

        if [ -n "$previous_term_trap" ]; then
            eval "$previous_term_trap"
        else
            trap - TERM
        fi
    }

    function _checkbox_exit_with_report() {
        local status="$1"
        _checkbox_cleanup
        if type print_install_report > /dev/null 2>&1; then
            print_install_report
        fi
        _checkbox_restore_traps
        exit "$status"
    }

    previous_int_trap=$(trap -p INT || true)
    previous_term_trap=$(trap -p TERM || true)
    trap '_checkbox_exit_with_report 130' INT
    trap '_checkbox_exit_with_report 143' TERM

    function _checkbox_render_line() {
        local line_index="$1"
        local cursor=" "
        local mark="${gray}[ ]${reset}"
        local item_style="${reset}"
        local screen_row=""
        local screen_col=""
        local plain_text=""
        local padding=0

        if [ "${selected[line_index]}" -eq 1 ]; then
            mark="${green}[x]${reset}"
        fi
        if [ "$line_index" -eq "$current" ]; then
            cursor="${yellow}>${reset}"
            item_style="${bold}"
        fi

        read -r screen_row screen_col < <(_checkbox_position_for_index "$line_index")
        plain_text="> [x] ${items[line_index]}"
        padding=$((cell_width - ${#plain_text}))
        if [ "$padding" -lt 0 ]; then
            padding=0
        fi

        printf '[%s;%sH%s %b %b%s%b%*s' "$screen_row" "$screen_col" "$cursor" "$mark" "$item_style" "${items[line_index]}" "$reset" "$padding" "" > /dev/tty
    }

    printf '\033[?25l' > /dev/tty
    for ((index = 0; index < menu_height; index++)); do
        printf '\n' > /dev/tty
    done
    printf '\033[%s;1H%b%s%b\n' "$menu_top" "$bold$cyan" 'Dotfiles installer' "$reset" > /dev/tty
    printf '%b%s%b\n' "$bold" "$title" "$reset" > /dev/tty
    printf '%bNavigation:%b Up/Down/Left/Right\n' "$dim" "$reset" > /dev/tty
    printf '%bToggle item:%b Space\n' "$dim" "$reset" > /dev/tty
    printf '%bSelect all:%b a\n' "$dim" "$reset" > /dev/tty
    printf '%bDeselect all:%b n\n' "$dim" "$reset" > /dev/tty
    printf '%bConfirm:%b Enter\n\n' "$dim" "$reset" > /dev/tty

    for ((index = 0; index < ${#items[@]}; index++)); do
        _checkbox_render_line "$index"
    done

    while true; do
        IFS= read -rsn1 key < /dev/tty
        previous="$current"
        case "$key" in
            "")
                break
                ;;
            " ")
                if [ "${selected[current]}" -eq 1 ]; then
                    selected[current]=0
                else
                    selected[current]=1
                fi
                _checkbox_render_line "$current"
                ;;
            "a"|"A")
                for ((index = 0; index < ${#selected[@]}; index++)); do
                    selected[index]=1
                    _checkbox_render_line "$index"
                done
                ;;
            "n"|"N")
                for ((index = 0; index < ${#selected[@]}; index++)); do
                    selected[index]=0
                    _checkbox_render_line "$index"
                done
                ;;
            $'\x1b')
                IFS= read -rsn2 -t 0.1 key_rest < /dev/tty
                case "$key_rest" in
                    "[A")
                        if [ "$((current % row_count))" -gt 0 ]; then
                            current=$((current - 1))
                        fi
                        ;;
                    "[B")
                        if [ "$((current % row_count))" -lt "$((row_count - 1))" ] && [ "$((current + 1))" -lt "${#items[@]}" ]; then
                            current=$((current + 1))
                        fi
                        ;;
                    "[D")
                        if [ "$current" -ge "$row_count" ]; then
                            current=$((current - row_count))
                        fi
                        ;;
                    "[C")
                        if [ "$((current + row_count))" -lt "${#items[@]}" ]; then
                            current=$((current + row_count))
                        fi
                        ;;
                esac
                if [ "$previous" -ne "$current" ]; then
                    _checkbox_render_line "$previous"
                    _checkbox_render_line "$current"
                fi
                ;;
        esac
    done

    _checkbox_restore_traps
    printf '[%s;1H[?25h
' "$((start_row + row_count))" > /dev/tty
    for ((index = 0; index < ${#selected[@]}; index++)); do
        if [ "${selected[index]}" -eq 1 ]; then
            printf '%s
' "$index"
        fi
    done
}
