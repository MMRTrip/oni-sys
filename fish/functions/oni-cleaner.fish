function oni-cleaner --description 'Oni-Sys: Ритуал экзорцизма кэша и освобождения RAM'
    set -l c_red (set_color -o red)
    set -l c_mag (set_color -o magenta)
    set -l c_dark (set_color brblack)
    set -l c_reset (set_color normal)

    echo "$c_mag[ ONI-SYS :: НАЧАЛО РИТУАЛА ОЧИСТКИ ]$c_reset"

    echo -n $c_dark; echo -n "oni: "; echo -n $c_reset; echo "Запрос прав на изгнание цифрового мусора..."
    if not sudo -v
        echo -n $c_red; echo -n "Ошибка: "; echo -n $c_reset; echo "Ритуал прерван."
        return 1
    end

    # 1. Изгоняем кэш эскизов и картинок KDE Plasma (часто весит больше 1 ГБ)
    echo ""
    echo "$c_red◆$c_reset Очистка кэша эскизов и иконок KDE..."
    rm -rf ~/.cache/thumbnails/* 2>/dev/null
    rm -rf ~/.cache/icon-cache.kcache 2>/dev/null

    # 2. Сжатие логов systemd (оставляем только последние 50 МБ)
    echo "$c_red◆$c_reset Сжатие разросшихся системных логов..."
    sudo journalctl --vacuum-size=50M

    # 3. Самая важная магия для 4 ГБ RAM — сброс кэша страниц памяти в ядре Linux
    echo "$c_red◆$c_reset Освобождение заблокированной оперативной памяти..."
    # Синхронизируем диск, чтобы не потерять данные, и принудительно чистим pagecache, dentries и inodes
    sudo sync; and sudo sysctl -w vm.drop_caches=3

    echo ""
    echo -n $c_mag; echo -n "└──[ РИТУАЛ ЗАВЕРШЕН :: ОПЕРАТИВКА ОЧИЩЕНА ]──┘"; echo $c_reset

    # Сочное уведомление в Plasma
    notify-send "Oni-Sys Cleaner" "Духи мусора изгнаны! Оперативная память свободна." --icon=edit-clear-all
end
