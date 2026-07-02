function oni-update --description 'Oni-Sys Intelligent System Updater (Low-RAM Safety Edition)'
    set -l c_red (set_color -o red)
    set -l c_mag (set_color -o magenta)
    set -l c_dark (set_color brblack)
    set -l c_reset (set_color normal)

    echo "$c_mag"[ ONI-SYS :: STARTING SYSTEM UPDATE ]"$c_reset"

    echo "$c_dark"[oni]"$c_reset Проверка прав демона..."
    if not sudo -v
        echo "$c_red[Ошибка]$c_reset Отказ в доступе. Обновление отменено."
        return 1
    end

    # ЗАЩИТА 4 ГБ RAM: Ограничиваем аппетиты компилятора при сборке AUR пакетов
    # Говорим makepkg использовать не более 2 потоков и не жрать всю память
    set -gx MAKEFLAGS "-j2"
    # На всякий случай заставляем утилиты сборки сжимать пакеты быстрее через zstd
    set -gx COMPRESSZST "zstd -c -T2 --fast"

    # Фикс блокировок перед стартом: если pacman упал ранее, удаляем застрявший lock-файл
    if test -f /var/lib/pacman/db.lck
        echo "$c_red[Внимание]$c_reset Обнаружен застрявший db.lck! Снимаю оковы..."
        sudo rm /var/lib/pacman/db.lck
    end

    # Шаг 1: Обновление репозиториев и AUR через yay
    echo ""
    echo "$c_red◆$c_reset Синхронизация pacman & yay..."
    # Ограничиваем приоритет ввода-вывода (ionice), чтобы во время апдейта можно было сидеть в браузере
    ionice -c 3 nice -n 10 yay -Syu

    if test $status -eq 0
        echo ""
        echo "$c_mag"[Успех]"$c_reset Основные пакеты синхронизированы."
    else
        echo ""
        echo "$c_red[Внимание]$c_reset Что-то пошло не так или обновление прервано."
        notify-send "Oni-Sys Update" "Обновление прервано или завершилось с ошибкой" --icon=dialog-warning
        return 1
    end

    # Шаг 2: Поиск и удаление сирот (orphans)
    echo ""
    echo "$c_red◆$c_reset Поиск неприкаянных душ (orphans)..."
    set -l orphans (pacman -Qdtq)
    if test -n "$orphans"
        echo "$c_dark"[oni]"$c_reset Найдено пакетов-сирот: "(count $orphans)
        # Оптимизация: убираем лишние вопросы pacman
        sudo pacman -Rns --noconfirm $orphans
    else
        echo "$c_dark"[oni]"$c_reset Система чиста. Сирот не обнаружено."
    end

    # Шаг 3: Очистка кэша и исправление багов pacman
    echo ""
    echo "$c_red◆$c_reset Ритуал очистки кэша пакетов..."

    # Прячем wildcard от парсера Fish внутрь утилиты find. Теперь сбоев не будет 100%
    set -l bad_dirs (find /var/cache/pacman/pkg/ -maxdepth 1 -type d -name "download-*" 2>/dev/null)
    if test -n "$bad_dirs"
        sudo rm -rf $bad_dirs
        echo "$c_dark[oni]$c_reset Остаточные темп-директории pacman зачищены."
    end



    # Твой крутой фикс бага "Error reading fd 7"
    if sudo rm -rf /var/cache/pacman/pkg/download-* 2>/dev/null
        echo "$c_dark[oni]$c_reset Остаточные темп-директории pacman зачищены."
    end

    # Жесткая экономия места: оставляем ТОЛЬКО 1 прошлую версию пакета на случай отката (вместо дефолтных 3)
    if command -v paccache > /dev/null
        echo "$c_dark[oni]$c_reset Очистка старого кэша через paccache (оставляем 1 копию)..."
        sudo paccache -r -k 1
        # Дополнительно чистим кэш удаленных пакетов полностью
        sudo paccache -ruk 0
    else
        yay -Sc --noconfirm
    end

    # Финал
    echo ""
    echo "$c_mag"└──[ ONI-SYS :: UPDATE COMPLETE ]──┘"$c_reset"

    notify-send "Oni-Sys Active" "Система полностью обновлена и очищена!" --icon=system-software-update --urgency=normal
end
