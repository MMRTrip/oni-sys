function oni-backup --description 'Oni-Sys Cloud Git Backup with Package Lists (Low-RAM Optimized)'
    set -l c_red (set_color -o red)
    set -l c_mag (set_color -o magenta)
    set -l c_dark (set_color brblack)
    set -l c_reset (set_color normal)

    # Путь к твоему локальному репозиторию
    set -l repo_dir ~/Oni-Sys-Backups

    echo "$c_mag"[Oni-Sys]"$c_reset Синхронизация репозитория дотфайлов..."

    # Создаем структуру папок (включая yakuake/konsole)
    mkdir -p $repo_dir/fish/functions
    mkdir -p $repo_dir/starship
    mkdir -p $repo_dir/packages
    mkdir -p $repo_dir/yakuake
    mkdir -p $repo_dir/konsole

    echo "$c_dark"[oni]"$c_reset Инвентаризация установленного софта..."

    # Запускаем сбор пакетов с пониженным приоритетом ввода-вывода (ionice), чтоб не фризило диск
    ionice -c 3 pacman -Qentq > $repo_dir/packages/pacman-list.txt
    ionice -c 3 pacman -Qemq > $repo_dir/packages/aur-list.txt

    echo "$c_dark"[oni]"$c_reset Копирование демонических конфигов..."

    # Твои старые конфиги
    cp ~/.config/fish/config.fish $repo_dir/fish/
    cp ~/.config/fish/functions/oni-*.fish $repo_dir/fish/functions/
    cp ~/.config/starship*.toml $repo_dir/starship/ 2>/dev/null

    # Вкатываем свежие конфиги Yakuake и Konsole, которые настроили
    cp ~/.config/yakuakerc $repo_dir/yakuake/ 2>/dev/null
    cp ~/.local/share/konsole/OniSysYakuake.* $repo_dir/konsole/ 2>/dev/null

    # Переходим в папку репозитория
    cd $repo_dir

    # Оптимизированная проверка изменений: git diff-index работает в разы быстрее, чем парсинг строки status
    if not git diff-index --quiet HEAD --
        set -l date_str (date +%Y-%m-%d_%H-%M)

        # Перекладываем коммит на минимальный приоритет процессора (nice -n 19), экономим циклы RAM
        nice -n 19 git add .
        nice -n 19 git commit -m "Oni-Sys Backup: $date_str (Configs & Package Lists)"

        echo "$c_dark"[oni]"$c_reset Отправка данных в демоническое облако GitHub..."

        if nice -n 19 git push origin main
            echo "$c_mag"[Успех]"$c_reset Все дотфайлы и списки софта улетели на GitHub!"
            notify-send "Oni-Sys Backup" "Конфиги и списки софта сохранены на GitHub!" --icon=vcs-normal
        else
            echo "$c_red"[Ошибка]"$c_reset Не удалось отправить файлы. Проверь сеть или SSH."
            notify-send "Oni-Sys Backup" "Ошибка отправки бэкапа на GitHub!" --icon=dialog-error
        end
    else
        echo "$c_dark"[oni]"$c_reset Изменений не обнаружено. Бэкап не требуется."
    end

    cd -
end
