#!/usr/bin/env fish

# Ждем 3 секунды, чтобы инициализировался экран
sleep 10

clear
echo "===================================================="
echo "         ЗАПУСК АВТОНОМНОГО УСТАНОВЩИКА             "
echo "===================================================="

# Запускаем инсталлятор, который лежит в корне репозитория
if test -f /run/archiso/bootmnt/oni-install.fish
    fish /run/archiso/bootmnt/oni-install.fish
else
    # Если запуск идет из chroot/облака, ищем локальную копию
    fish /usr/local/bin/oni-install.fish
end
