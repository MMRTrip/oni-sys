function oni-widget --description 'Oni-Sys: Нативный генератор виджета погоды под обои'
    # Скрипт принимает два аргумента: исходные обои и файл на выходе
    set -l input_wp $argv[1]
    set -l output_wp $argv[2]

    if not test -f "$input_wp"
        return 1
    end

    # Вытаскиваем погоду в Чите
    set -l weather_text (curl -s --max-time 4 "wttr.in/Chita?format=%c+%t" | string trim)
    if test -z "$weather_text"
        set weather_text "Oni-Sys: Сбой сети"
    end

    # Рендерим текст точно над геймпадом (координаты +45+600)
    magick "$input_wp" \
        -font "Hack-Bold" -pointsize 16 \
        -fill "#ff2a5f" -annotate +75+700 "👹 Chita: $weather_text" \
        "$output_wp"
end
