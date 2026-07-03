function oni-backup --description 'Oni-Sys Cloud Git Backup with Package Lists (Low-RAM Optimized)'
    set -l c_red (set_color -o red)
    set -l c_mag (set_color -o magenta)
    set -l c_dark (set_color brblack)
    set -l c_reset (set_color normal)

    # Путь к твоему локальному репозиторию
    set -l repo_dir ~/Oni-Sys-Backups

    echo "$c_mag"[Oni-Sys]"$c_reset Синхронизация репозитория дотфайлов..."

    # Создаем структуру папок
    mkdir -p $repo_dir/fish/functions
    mkdir -p $repo_dir/starship
    mkdir -p $repo_dir/packages
    mkdir -p $repo_dir/yakuake
    mkdir -p $repo_dir/konsole

    echo "$c_dark"[oni]"$c_reset Инвентаризация установленного софта..."

    # Запускаем сбор пакетов с пониженным приоритетом ввода-вывода (ionice)
    ionice -c 3 pacman -Qentq > $repo_dir/packages/pacman-list.txt
    ionice -c 3 pacman -Qemq > $repo_dir/packages/aur-list.txt

    echo "$c_dark"[oni]"$c_reset Копирование демонических конфигов..."

    # Копируем конфиги Fish, включая oni-* и vbi-* функции
    cp ~/.config/fish/config.fish $repo_dir/fish/
    cp ~/.config/fish/functions/oni-*.fish $repo_dir/fish/functions/
    cp ~/.config/fish/functions/vbi-*.fish $repo_dir/fish/functions/ 2>/dev/null
    cp ~/.config/starship*.toml $repo_dir/starship/ 2>/dev/null

    # Вкатываем свежие конфиги Yakuake и Konsole
    cp ~/.config/yakuakerc $repo_dir/yakuake/ 2>/dev/null
    cp ~/.local/share/konsole/OniSysYakuake.* $repo_dir/konsole/ 2>/dev/null

    # Переходим в папку репозитория
    cd $repo_dir

    # Проверяем изменения локально, глуша весь мусорный вывод в /dev/null
    if not git diff-index --quiet HEAD -- 2>/dev/null
        set -l date_str (date +%Y-%m-%d_%H-%M)

        # Коммитим тихо без вывода лишних строк
        nice -n 19 git add . >/dev/null 2>&1
        nice -n 19 git commit -m "Oni-Sys Backup: $date_str (Configs & Package Lists)" >/dev/null 2>&1

        echo "$c_dark"[oni]"$c_reset Отправка данных в демоническое облако GitHub..."

        # Пушим абсолютно молча (флаг -q / --quiet), перенаправляя весь поток вывода
        if nice -n 19 git push -q origin main >/dev/null 2>&1
            echo "$c_mag"[Успех]"$c_reset Все дотфайлы и списки софта улетели на GitHub!"
            notify-send "Oni-Sys Backup" "👹 Конфиги и списки софта сохранены на GitHub!" --icon=dialog-information
        else
            echo "$c_red"[Ошибка]"$c_reset Не удалось отправить файлы. Проверь сеть."
            notify-send "Oni-Sys Backup" "❌ Ошибка отправки бэкапа на GitHub!" --icon=dialog-error
        end
    else
        echo "$c_dark"[oni]"$c_reset Изменений не обнаружено. Бэкап не требуется."
    end

    # Возвращаемся назад без лишнего мусора в терминале
    cd - >/dev/null
end
