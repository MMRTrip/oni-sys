function oni-backup --description 'Oni-Sys Cloud Git Backup with Package Lists'
    set -l c_red (set_color -o red)
    set -l c_mag (set_color -o magenta)
    set -l c_dark (set_color brblack)
    set -l c_reset (set_color normal)

    set -l repo_dir ~/Oni-Sys-Backups

    echo "$c_mag"[Oni-Sys]"$c_reset Синхронизация репозитория дотфайлов..."

    # Создаем структуру папок
    mkdir -p $repo_dir/fish/functions
    mkdir -p $repo_dir/starship
    mkdir -p $repo_dir/packages

    # 1. Генерируем списки установленного софта (Oni Package Tracker)
    echo "$c_dark"[oni]"$c_reset Инвентаризация установленного софта..."
    # Явный список пакетов из официальных репозиториев (без зависимостей)
    pacman -Qentq > $repo_dir/packages/pacman-list.txt
    # Список пакетов, установленных только из AUR
    pacman -Qemq > $repo_dir/packages/aur-list.txt

    # 2. Копируем актуальные конфиги
    cp ~/.config/fish/config.fish $repo_dir/fish/
    cp ~/.config/fish/functions/oni-*.fish $repo_dir/fish/functions/
    cp ~/.config/starship*.toml $repo_dir/starship/ 2>/dev/null

    # 3. Переходим в папку репозитория и пушим на GitHub
    cd $repo_dir
    
    if test -n "$(git status --porcelain)"
        set -l date_str (date +%Y-%m-%d_%H-%M)
        git add .
        git commit -m "Oni-Sys Backup: $date_str (Configs & Package Lists)"
        
        echo "$c_dark"[oni]"$c_reset Отправка данных в демоническое облако GitHub..."
        if git push origin main
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
