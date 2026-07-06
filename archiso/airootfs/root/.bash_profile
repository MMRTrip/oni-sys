# Автостарт инсталлятора Oni-Sys
if [[ -z "$DISPLAY" && $(tty) == /dev/tty1 ]]; then
    exec fish /usr/local/bin/oni-autostart-installer.fish
fi
