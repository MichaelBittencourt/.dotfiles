fish_add_path -g ~/.local/bin
fish_add_path -g ~/.cargo/bin

if status is-interactive
    # Commands to run in interactive sessions can go here
    if which exa
        function ls
            exa --icons $argv
        end
    end
    if which lvim
        function vim
            lvim $argv
        end
    end

    function psfwu
        ps aux | grep fwupd
    end

    function kpsfwu
        psfwu | grep -v grep | grep root | awk {'print$2""'} | xargs sudo kill -9
    end

    function pszygote
        command adb shell ps | grep " zygote" | grep -v grep
    end

    function kzygote
        for i in (pszygote | grep root | awk {'print$2""'})
            adb shell kill -9 "$i"
        end
    end

    function nmux
        lvim -c "Neomux"
    end

    function crlf2lf
        cat "$argv[1]" | tr -d '\015' > "$argv[2]"
    end

    # To add vim mode by default on fish interaction
    fish_vi_key_bindings
end

source ~/.asdf/asdf.fish
