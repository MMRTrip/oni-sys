function oni-update --description 'Oni-Sys Intelligent System Updater'
    set -l c_red (set_color -o red)
    set -l c_mag (set_color -o magenta)
    set -l c_dark (set_color brblack)
    set -l c_reset (set_color normal)

    echo "$c_mag--- ONI-SYS :: STARTING SYSTEM UPDATE ---$c_reset"

    echo -n $c_dark; echo -n "oni: "; echo -n $c_reset; echo "Проверка прав демона..."
    if not sudo -v
        echo -n $c_red; echo -n "Ошибка: "; echo -n $c_reset; echo "Отказ в доступе. Обновление отменено."
        return 1
    end

    # === [ЖЕЛЕЗОБЕТОННАЯ ЗАЩИТА SUDO БЕЗ ЗАВИСАНИЙ] ===
    # Временно продлеваем таймаут sudo до 60 минут, чтобы долгая сборка AUR или Flatpak не сбросила пароль.
    # Создаем временный файл конфигурации.
    echo "Defaults timestamp_timeout=60" | sudo tee /etc/sudoers.d/oni-sys-timeout >/dev/null

    # Функция автозачистки временного файла при любом исходе
    function _oni_cleanup_sudo
        sudo rm -f /etc/sudoers.d/oni-sys-timeout >/dev/null 2>&1
    end

    # Шаг 1: Обновление репозиториев и AUR через yay
    echo ""
    echo "$c_red◆$c_reset Синхронизация pacman & yay..."
    yay -Syu

    if test $status -eq 0
        echo ""
        echo -n $c_mag; echo -n "Успех: "; echo -n $c_reset; echo "Основные пакеты синхронизированы."
    else
        echo ""
        echo -n $c_red; echo -n "Внимание: "; echo -n $c_reset; echo "Что-то пошло не так или обновление прервано."
        notify-send "Oni-Sys Update" "Обновление прервано или завершилось с ошибкой" --icon=dialog-warning
        _oni_cleanup_sudo
        return 1
    end

    # Шаг 2: Обновление Flatpak приложений и рантаймов
    if type -q flatpak
        echo ""
        echo "$c_red◆$c_reset Синхронизация плоских миров (Flatpak)..."

        # Запускаем обновление через sudo, чтобы appstream не вешал dbus
        sudo nice -n 19 flatpak update -y

        if test $status -eq 0
            echo -n $c_dark; echo -n "oni: "; echo -n $c_reset; echo "Удаление старых цифровых остатков Flatpak..."
            # Чистим неиспользуемые рантаймы тоже через sudo
            sudo nice -n 19 flatpak uninstall --unused -y >/dev/null 2>&1
        else
            echo -n $c_red; echo -n "Внимание: "; echo -n $c_reset; echo "Ошибка обновления Flatpak."
        end
    end

    # Шаг 3: Поиск и удаление сирот (orphans)
    echo ""
    echo "$c_red◆$c_reset Поиск неприкаянных душ (orphans)..."
    set -l orphans (pacman -Qdtq)
    if test -n "$orphans"
        echo -n $c_dark; echo -n "oni: "; echo -n $c_reset; echo "Найдено пакетов-сирот: "(count $orphans)
        sudo pacman -Rns $orphans
    else
        echo -n $c_dark; echo -n "oni: "; echo -n $c_reset; echo "Система чиста. Сирот не обнаружено."
    end

    # Шаг 4: Очистка кэша и исправление багов pacman
    echo ""
    echo "$c_red◆$c_reset Ритуал очистки кэша пакетов..."

    set -l bad_dirs (find /var/cache/pacman/pkg/ -maxdepth 1 -type d -name "download-*" 2>/dev/null)
    if test -n "$bad_dirs"
        sudo rm -rf $bad_dirs
        echo -n $c_dark; echo -n "oni: "; echo -n $c_reset; echo "Остаточные темп-директории pacman зачищены."
    end

    # Безопасная очистка кэша
    if command -v paccache > /dev/null
        sudo paccache -r
    else
        yay -Sc --noconfirm
    end

    # Финал
    echo ""
    echo -n $c_mag; echo -n "└──[ ONI-SYS :: UPDATE COMPLETE ]──┘"; echo $c_reset

    notify-send "Oni-Sys Active" "Система полностью обновлена и очищена!" --icon=system-software-update --urgency=normal

    # Возвращаем стандартные настройки безопасности sudo
    _oni_cleanup_sudo
end
