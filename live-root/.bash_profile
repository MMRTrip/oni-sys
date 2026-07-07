if [[ -z "$DISPLAY" && $(tty) == /dev/tty1 ]]; then
    exec fish /usr/local/bin/oni-install.fish
fi
