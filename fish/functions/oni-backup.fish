function oni-backup --description 'Oni-Sys Cloud Git Backup with Package Lists (Low-RAM Optimized)'
    set -l c_red (set_color -o red)
    set -l c_mag (set_color -o magenta)
    set -l c_dark (set_color brblack)
    set -l c_reset (set_color normal)

    # Твой точный путь к репозиторию ребилда
    set -l repo_dir /home/ilyushko/oni-sys-rebuild

    echo "$c_mag"[Oni-Sys]"$c_reset Синхронизация репозитория дотфайлов..."

    # Создаем структуру папок, если каких-то нет
    mkdir -p $repo_dir/fish/functions
    mkdir -p $repo_dir/starship
    mkdir -p $repo_dir/yakuake
    mkdir -p $repo_dir/konsole

    # Создаем пути для бэкапа твоей живой темы SDDM внутри структуры sizer
    set -l sddm_backup_dir $repo_dir/sizer/usr/share/sddm/themes/oni-sddm-theme
    mkdir -p $sddm_backup_dir

    echo "$c_dark"[oni]"$c_reset Инвентаризация установленного софта..."

    # Запускаем сбор пакетов с пониженным приоритетом ввода-вывода (ionice)
    ionice -c 3 pacman -Qentq > $repo_dir/packages/pacman-list.txt
    ionice -c 3 pacman -Qemq > $repo_dir/packages/aur-list.txt

    # Бэкап Flatpak списков и оверрайдов (Flatseal)
    if type -q flatpak
        ionice -c 3 flatpak list --app --columns=application > $repo_dir/packages/flatpak-list.txt

        # Безопасное пересоздание папки оверрайдов
        rm -rf $repo_dir/packages/flatpak-overrides
        mkdir -p $repo_dir/packages/flatpak-overrides

        set -l override_files ~/.local/share/flatpak/overrides/*
        if count $override_files >/dev/null
            cp $override_files $repo_dir/packages/flatpak-overrides/
        end
    end

    echo "$c_dark"[oni]"$c_reset Копирование демонических конфигов..."

    # Безопасное копирование основного конфига Fish и всех oni-* функций
    cp ~/.config/fish/config.fish $repo_dir/fish/
    cp ~/.config/fish/functions/oni-*.fish $repo_dir/fish/functions/

    # Копируем vbi-*, только если они реально существуют
    set -l vbi_files ~/.config/fish/functions/vbi-*.fish
    if count $vbi_files >/dev/null
        cp $vbi_files $repo_dir/fish/functions/
    end

    # Копируем конфиг Starship
    set -l starship_files ~/.config/starship*.toml
    if count $starship_files >/dev/null
        cp $starship_files $repo_dir/starship/
    end

    # Вкатываем свежие конфиги Yakuake и Konsole
    cp ~/.config/yakuakerc $repo_dir/yakuake/ 2>/dev/null
    cp ~/.local/share/konsole/OniSysYakuake.* $repo_dir/konsole/ 2>/dev/null

    echo "$c_dark"[oni]"$c_reset Синхронизация кастомной темы SDDM..."

    # Забираем актуальные файлы темы из системы в твой sizer
    set -l system_sddm_dir /usr/share/sddm/themes/my-sddm-theme
    if test -d $system_sddm_dir
        cp -r $system_sddm_dir/* $sddm_backup_dir/
    end

    # Переходим в папку репозитория
    cd $repo_dir

    # Шаг 1. Проверяем изменения и коммитим, если они есть
    set -l has_changes 0
    if not git diff-index --quiet HEAD -- 2>/dev/null
        set -l date_str (date +%Y-%m-%d_%H-%M)
        git add . >/dev/null 2>&1
        git commit -m "Oni-Sys Backup: $date_str (Configs, Packages, Flatpaks & SDDM)" >/dev/null 2>&1
        set has_changes 1
    end

    # Шаг 2. Отправка в облако
    echo "$c_dark"[oni]"$c_reset Отправка данных в демоническое облако GitHub..."

    # Запускаем пуш и ловим текстовый ответ
    set -l git_output (git push origin main 2>&1)
    set -l git_status $status

    # Шаг 3. Умный анализ результата
    if test $git_status -eq 0
        echo "$c_mag"[Успех]"$c_reset Все дотфайлы и списки софта улетели на GitHub!"
        notify-send "Oni-Sys Backup" "👹 Конфиги и списки софта сохранены на GitHub!" --icon=dialog-information
    else if string match -q "*Everything up-to-date*" "$git_output"
        echo "$c_dark"[oni]"$c_reset Изменений на GitHub не обнаружено. Локальный репозиторий синхронизирован."
    else
        echo "$c_red"[Ошибка]"$c_reset Git вернул сбой. Проверьте сеть."
        echo "$c_dark"[Детали]"$c_reset $git_output"
        notify-send "Oni-Sys Backup" "❌ Ошибка отправки бэкапа на GitHub!" --icon=dialog-error
    end

    # Возвращаемся назад без лишнего мусора в терминале
    cd - >/dev/null
end
