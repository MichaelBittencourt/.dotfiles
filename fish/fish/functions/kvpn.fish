function kvpn
    for i in $(ps aux | grep -e pulsesvc -e pulseUi | grep -v grep | awk '{ print $2 }')
        sudo kill -9 "$i"
    end
end
