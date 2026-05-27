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
    local max_cell_width=36
    local item_text_width=0
    local column_count=1
    local row_count=0
    local visible_row_count=0
    local max_visible_rows=0
    local row_offset=0
    local previous_row_offset=0
    local current_row=0
    local term_rows=24
    local menu_height=0
    local menu_top=1
    local detail_row=0
    local bottom_border_row=0
    local footer_row=0
    local frame_width=0
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
    if [ "$cell_width" -gt "$max_cell_width" ]; then
        cell_width="$max_cell_width"
    fi
    if [ "$cell_width" -gt "$term_cols" ]; then
        cell_width="$term_cols"
    fi
    item_text_width=$((cell_width - 6))
    if [ "$item_text_width" -lt 8 ]; then
        item_text_width=8
    fi
    column_count=$(((term_cols - 3) / cell_width))
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
    max_visible_rows=$((term_rows - 13))
    if [ "$max_visible_rows" -lt 5 ]; then
        max_visible_rows=5
    fi
    visible_row_count="$row_count"
    if [ "$visible_row_count" -gt "$max_visible_rows" ]; then
        visible_row_count="$max_visible_rows"
    fi
    frame_width=$((column_count * cell_width + 3))
    if [ "$frame_width" -gt "$term_cols" ]; then
        frame_width="$term_cols"
    fi
    menu_height=$((13 + visible_row_count))
    menu_top=$((term_rows - menu_height + 1))
    if [ "$menu_top" -lt 1 ]; then
        menu_top=1
    fi
    start_row=$((menu_top + 9))
    bottom_border_row=$((start_row + visible_row_count))
    detail_row=$((bottom_border_row + 1))
    footer_row=$((detail_row + 1))

    function _checkbox_position_for_index() {
        local line_index="$1"
        local row=$((line_index % row_count))
        local column=$((line_index / row_count))
        local screen_row=$((start_row + row))
        local screen_col=$((3 + column * cell_width))

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

    function _checkbox_render_cell() {
        local row="$1"
        local column="$2"
        local line_index=$((column * row_count + row))
        local screen_row=$((start_row + row - row_offset))
        local screen_col=$((3 + column * cell_width))
        local cursor=" "
        local mark="${gray}[ ]${reset}"
        local item_style="${reset}"
        local plain_text=""
        local display_text=""
        local padding=0

        if [ "$line_index" -ge "${#items[@]}" ]; then
            printf '[%s;%sH%*s' "$screen_row" "$screen_col" "$((cell_width - 1))" "" > /dev/tty
            return 0
        fi

        if [ "${selected[line_index]}" -eq 1 ]; then
            mark="${green}[x]${reset}"
        fi
        if [ "$line_index" -eq "$current" ]; then
            cursor="${yellow}>${reset}"
            item_style="${bold}"
        fi

        display_text="${items[line_index]}"
        if [ "${#display_text}" -gt "$item_text_width" ]; then
            display_text="${display_text:0:$((item_text_width - 3))}..."
        fi
        plain_text="> [x] ${display_text}"
        padding=$((cell_width - ${#plain_text}))
        if [ "$padding" -lt 0 ]; then
            padding=0
        fi

        printf '[%s;%sH%s %b %b%s%b%*s' "$screen_row" "$screen_col" "$cursor" "$mark" "$item_style" "$display_text" "$reset" "$padding" "" > /dev/tty
    }

    function _checkbox_render_visible_items() {
        local row=0
        local column=0

        for ((row = row_offset; row < row_offset + visible_row_count; row++)); do
            _checkbox_clear_row "$((start_row + row - row_offset))"
            printf '[%s;1H%b|%b' "$((start_row + row - row_offset))" "$dim" "$reset" > /dev/tty
            printf '[%s;%sH%b|%b' "$((start_row + row - row_offset))" "$frame_width" "$dim" "$reset" > /dev/tty
            for ((column = 0; column < column_count; column++)); do
                _checkbox_render_cell "$row" "$column"
            done
        done
    }


    function _checkbox_render_index_if_visible() {
        local line_index="$1"
        local row=$((line_index % row_count))
        local column=$((line_index / row_count))

        if [ "$row" -lt "$row_offset" ] || [ "$row" -ge "$((row_offset + visible_row_count))" ]; then
            return 0
        fi

        _checkbox_render_cell "$row" "$column"
    }

    function _checkbox_ensure_current_visible() {
        current_row=$((current % row_count))

        if [ "$current_row" -lt "$row_offset" ]; then
            row_offset="$current_row"
        elif [ "$current_row" -ge "$((row_offset + visible_row_count))" ]; then
            row_offset=$((current_row - visible_row_count + 1))
        fi
    }

    function _checkbox_clear_row() {
        local row="$1"

        printf '[%s;1H[2K' "$row" > /dev/tty
    }

    function _checkbox_render_horizontal_border() {
        local row="$1"

        printf '[%s;1H%b+%s+%b' "$row" "$dim" "$(printf '%*s' "$((frame_width - 2))" '' | tr ' ' '-')" "$reset" > /dev/tty
    }

    function _checkbox_render_vertical_borders() {
        local row=0

        for ((row = start_row; row < bottom_border_row; row++)); do
            printf '[%s;1H%b|%b' "$row" "$dim" "$reset" > /dev/tty
            printf '[%s;%sH%b|%b' "$row" "$frame_width" "$dim" "$reset" > /dev/tty
        done
    }

    function _checkbox_render_detail() {
        local detail_text="${items[current]}"
        local max_detail_width=$((term_cols - 11))

        if [ "$max_detail_width" -lt 20 ]; then
            max_detail_width=20
        fi
        if [ "${#detail_text}" -gt "$max_detail_width" ]; then
            detail_text="${detail_text:0:$((max_detail_width - 3))}..."
        fi

        _checkbox_clear_row "$detail_row"
        printf '[%s;1H%bRows:%b %s-%s/%s  %bSelected:%b %s' "$detail_row" "$dim" "$reset" "$((row_offset + 1))" "$((row_offset + visible_row_count))" "$row_count" "$dim" "$reset" "$detail_text" > /dev/tty
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
    _checkbox_render_horizontal_border "$((start_row - 1))"
    _checkbox_render_vertical_borders
    _checkbox_render_horizontal_border "$bottom_border_row"
    _checkbox_render_detail

    _checkbox_render_visible_items

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
                _checkbox_render_visible_items
                _checkbox_render_detail
                ;;
            "a"|"A")
                for ((index = 0; index < ${#selected[@]}; index++)); do
                    selected[index]=1
                done
                _checkbox_render_visible_items
                ;;
            "n"|"N")
                for ((index = 0; index < ${#selected[@]}; index++)); do
                    selected[index]=0
                done
                _checkbox_render_visible_items
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
                    previous_row_offset="$row_offset"
                    _checkbox_ensure_current_visible
                    if [ "$previous_row_offset" -ne "$row_offset" ]; then
                        _checkbox_render_visible_items
                    else
                        _checkbox_render_index_if_visible "$previous"
                        _checkbox_render_index_if_visible "$current"
                    fi
                    _checkbox_render_detail
                fi
                ;;
        esac
    done

    _checkbox_restore_traps
    printf '\033[%s;1H\033[?25h\n\n\n' "$footer_row" > /dev/tty
    for ((index = 0; index < ${#selected[@]}; index++)); do
        if [ "${selected[index]}" -eq 1 ]; then
            printf '%s
' "$index"
        fi
    done
}
