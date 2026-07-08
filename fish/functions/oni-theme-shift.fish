function oni-theme-shift --description 'Toggle Oni-Sys themes (calm / game)'
    set -l mode $argv
    set -l c_red (set_color -o red)
    set -l c_mag (set_color -o magenta)
    set -l c_reset (set_color normal)

    if test -z "$mode"
        echo "$c_red[Ошибка]$c_reset Укажи режим! Использование: oni-theme-shift calm или oni-theme-shift game"
        return 1
    end

    switch $mode
        case calm
            echo (set_color ff2a5f)"[Oni-Sys] "(set_color normal)"Активация режима: Спокойный Они..."

            # Определяем исходный файл
            set -l src_img ""
            if test -f ~/Изображения/oni_calm.png
                set src_img ~/Изображения/oni_calm.png
            else if test -f ~/Изображения/oni_calm.jpg
                set src_img ~/Изображения/oni_calm.jpg
            end

            if test -n "$src_img"
                # Запускаем синоптика, он рисует погоду на картинке и сохраняет в /tmp/
                oni-widget "$src_img" /tmp/oni_calm_weather.png
                # Нативно применяем обои со вшитым виджетом погоды!
                plasma-apply-wallpaperimage /tmp/oni_calm_weather.png > /dev/null 2>&1
            end

            if test -f ~/.config/starship_calm.toml
                cp ~/.config/starship_calm.toml ~/.config/starship.toml
            end

            notify-send "Oni-Sys: Режим Спокойствия" "Накири Аямэ отдыхает. Настройки графики обновлены." --icon=paddles --urgency=low

        case game
            echo (set_color ff2a5f)"[Oni-Sys] "(set_color normal)"Активация режима: ИГРОВОЙ ОНИ!"

            set -l src_img ""
            if test -f ~/Изображения/oni_battle.jpg
                set src_img ~/Изображения/oni_battle.jpg
            else if test -f ~/Изображения/oni_battle.png
                set src_img ~/Изображения/oni_battle.png
            end

            if test -n "$src_img"
                # Рисуем погоду на боевых обоях
                oni-widget "$src_img" /tmp/oni_battle_weather.png
                # Нативно применяем боевые обои с погодой
                plasma-apply-wallpaperimage /tmp/oni_battle_weather.png > /dev/null 2>&1
            end

            if test -f ~/.config/starship_battle.toml
                cp ~/.config/starship_battle.toml ~/.config/starship.toml
            end

            notify-send "Oni-Sys: ИГРОВОЙ РЕЖИМ" "Режим Они-Геймера активирован! Производительность на максимум!" --icon=applications-games --urgency=normal

        case '*'
            echo "$c_red[Ошибка]$c_reset Неизвестный режим: $mode. Доступны только: calm / game"
            return 1
    end

    set -g STARSHIP_CONFIG ~/.config/starship.toml
    echo (set_color 00ff7f)"[Успех] "(set_color normal)"Конфигурация Oni-Sys успешно перестроена."
end
