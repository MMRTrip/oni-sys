function oni-fetch --description 'Oni-Sys Bottom System Fetch'
    # Цвета: 91 (Bold Red), 35 (Bold Magenta)
    set -l c_red (set_color -o red)
    set -l c_mag (set_color -o magenta)
    set -l c_dark (set_color brblack)
    set -l c_reset (set_color normal)
    
    # Быстрый сбор инфы без внешних утилит
    # Используем нативную переменную Fish $hostname и переводим в верхний регистр
    set -l user_host (string upper "$USER@$hostname")
    set -l kernel (uname -r)
    set -l uptime (uptime -p | string replace "up " "")
    set -l pkgs (pacman -Q | count)
    set -l ram_info (free -m | awk '/Mem:/ {print $3,$2}')
    set -l ram_used (echo $ram_info | cut -d' ' -f1)
    set -l ram_total (echo $ram_info | cut -d' ' -f2)

    # Отрезаем лишнее от версии Fish
    set -l fish_v (echo $FISH_VERSION | cut -d'-' -f1)

    # Вывод информационного блока Oni-Sys (экранируем скобки)
    echo "                      $c_mag"[ ONI SYSTEM DATA ]"$c_reset"
    echo "  $c_red┌────────────────────────────────────────────────────────┐$c_reset"
    echo "    $c_dark HOST:$c_reset   $user_host" \
         "    $c_dark KERNEL:$c_reset $kernel"
    echo "    $c_dark UPTIME:$c_reset $uptime" \
         "    $c_dark PACKAGES:$c_reset $pkgs (pacman)"
    echo "    $c_dark SHELL:$c_reset  Fish $fish_v" \
         "    $c_dark MEMORY:$c_reset  $ram_used""MiB / $ram_total""MiB"
    echo "  $c_red└────────────────────────────────────────────────────────┘$c_reset"
    
    # Цветовая палитра (Индикаторы системы Они)
    echo -n "    "
    for col in (set_color -b black) (set_color -b red) (set_color -b brred) (set_color -b magenta) (set_color -b brmagenta) (set_color -b normal)
        echo -n "$col      "
    end
    echo "$c_reset"
    echo ""
end
