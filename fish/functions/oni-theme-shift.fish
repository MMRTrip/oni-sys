function oni-theme-shift --description 'Toggle Oni-Sys themes (calm / game)'
    set -l mode $argv
    set -l c_red (set_color -o red)
    set -l c_mag (set_color -o magenta)
    set -l c_reset (set_color normal)

    if test -z "$mode"
        echo "$c_red"[Ошибка]"$c_reset Укажи режим! Использование: oni-theme-shift calm или oni-theme-shift game"
        return 1
    end

    switch $mode
        case calm
            echo "$c_mag"[Oni-Sys]"$c_reset Активация режима: Спокойный Они..."
            
            if test -f ~/Изображения/oni_calm.png
                plasma-apply-wallpaperimage ~/Изображения/oni_calm.png > /dev/null 2>&1
            else if test -f ~/Изображения/oni_calm.jpg
                plasma-apply-wallpaperimage ~/Изображения/oni_calm.jpg > /dev/null 2>&1
            end
            
            if test -f ~/.config/starship_calm.toml
                cp ~/.config/starship_calm.toml ~/.config/starship.toml
            end
            
            notify-send "Oni-Sys: Режим Спокойствия" "Накири Аямэ отдыхает. Настройки графики обновлены." --icon=paddles --urgency=low

        case game
            echo "$c_red"[Oni-Sys]"$c_reset Активация режима: ИГРОВОЙ ОНИ!"
            
            # Подхватываем твой сочный арт с катаной (он остается oni_battle, либо можешь переименовать файл в oni_game)
            if test -f ~/Изображения/oni_battle.jpg
                plasma-apply-wallpaperimage ~/Изображения/oni_battle.jpg > /dev/null 2>&1
            else if test -f ~/Изображения/oni_battle.png
                plasma-apply-wallpaperimage ~/Изображения/oni_battle.png > /dev/null 2>&1
            end
            
            if test -f ~/.config/starship_battle.toml
                cp ~/.config/starship_battle.toml ~/.config/starship.toml
            end
            
            notify-send "Oni-Sys: ИГРОВОЙ РЕЖИМ" "Режим Они-Геймера активирован! Производительность на максимум!" --icon=applications-games --urgency=normal

        case '*'
            echo "$c_red"[Ошибка]"$c_reset Неизвестный режим: $mode. Доступны только: calm / game"
            return 1
    end

    set -g STARSHIP_CONFIG ~/.config/starship.toml
    echo "$c_mag"[Успех]"$c_reset Конфигурация Oni-Sys успешно перестроена."
end
