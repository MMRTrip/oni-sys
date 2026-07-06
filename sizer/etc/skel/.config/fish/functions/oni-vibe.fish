function oni-cleaner --description 'Oni-Sys: Ритуал экзорцизма кэша и освобождения RAM'
    set -l c_red (set_color -o red)
    set -l c_mag (set_color -o magenta)
    set -l c_dark (set_color brblack)
    set -l c_reset (set_color normal)

    echo -n $c_mag; echo "--- ONI-SYS :: НАЧАЛО РИТУАЛА ОЧИСТКИ ---"; echo -n $c_reset

    echo -n $c_dark; echo -n "oni: "; echo -n $c_reset; echo "Запрос прав на изгнание цифрового мусора..."
    if not sudo -v
        echo -n $c_red; echo -n "Ошибка: "; echo -n $c_reset; echo "Ритуал прерван."
        return 1
    end

    # 1. Изгоняем кэш эскизов и картинок KDE Plasma
    echo ""
    echo "$c_red◆$c_reset Очистка кэша эскизов и иконок KDE..."
    rm -rf ~/.cache/thumbnails/* 2>/dev/null
    rm -rf ~/.cache/icon-cache.kcache 2>/dev/null

    # 2. Сжатие логов systemd
    echo "$c_red◆$c_reset Сжатие разросшихся системных логов..."
    sudo journalctl --vacuum-size=50M

    # 3. Сброс кэша страниц памяти в ядре Linux
    echo "$c_red◆$c_reset Освобождение заблокированной оперативной памяти..."
    sudo sync; and sudo sysctl -w vm.drop_caches=3

    echo ""
    echo -n $c_mag; echo "└──[ РИТУАЛ ЗАВЕРШЕН :: ОПЕРАТИВКА ОЧИЩЕНА ]──┘"; echo $c_reset

    notify-send "Oni-Sys Cleaner" "Духи мусора изгнаны! Оперативная память свободна." --icon=edit-clear-all
end
