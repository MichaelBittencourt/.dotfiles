function restart_audio
    pulseaudio -k && sudo alsa force-reload
end
