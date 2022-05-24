function show
    if [ (count $argv) -gt 0 ]
        set -f ext "$(echo $argv[(count $argv)] | sed "s/^.*\.//g")"
        set -f program ""
        switch $ext
            case mp4 avi 3gp rmvb
                set -f program "mplayer"
                if [ "$argv[1]" = "ascii" ]
                    set -f program "$program -vo caca $argv[2..]"
                else
                    echo false
                    set -f program "$program $argv" 
                end
            case '*'
                echo "Open xdg-open"
                set -f program "xdg-open $argv"
        end
        $SHELL -c $program
    end
end
