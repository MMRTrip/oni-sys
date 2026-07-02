function oni-update --description 'Oni-Sys Intelligent System Updater'
    set -l c_red (set_color -o red)
    set -l c_mag (set_color -o magenta)
    set -l c_dark (set_color brblack)
    set -l c_reset (set_color normal)

    echo "$c_mag"[ ONI-SYS :: STARTING SYSTEM UPDATE ]"$c_reset"
    
    # Исправлено: экранируем скобки, чтобы Fish не думал, что это индекс массива
    echo "$c_dark"[oni]"$c_reset Проверка прав демона..."
    if not sudo -v
        echo "$c_red[Ошибка]$c_reset Отказ в доступе. Обновление отменено."
        return 1
    end

    # Шаг 1: Обновление репозиториев и AUR через yay
    echo ""
    echo "$c_red◆$c_reset Синхронизация pacman & yay..."
    yay -Syu

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
        sudo pacman -Rns $orphans
    else
        echo "$c_dark"[oni]"$c_reset Система чиста. Сирот не обнаружено."
    end

    # Шаг 3: Очистка кэша и исправление багов pacman
    echo ""
    echo "$c_red◆$c_reset Ритуал очистки кэша пакетов..."
    
    # Срезаем баг pacman (Error reading fd 7), принудительно удаляя застрявшие темп-папки
    if sudo rm -rf /var/cache/pacman/pkg/download-* 2>/dev/null
        echo "$c_dark[oni]$c_reset Остаточные темп-директории pacman зачищены."
    end

    # Безопасная очистка кэша
    if command -v paccache > /dev/null
        sudo paccache -r
    else
        yay -Sc --noconfirm
    end

    # Финал
    echo ""
    echo "$c_mag"└──[ ONI-SYS :: UPDATE COMPLETE ]──┘"$c_reset"
    
    # Отправляем сочное уведомление в KDE Plasma
    notify-send "Oni-Sys Active" "Система полностью обновлена и очищена!" --icon=system-software-update --urgency=normal
end
