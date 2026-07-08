function oni-weather --description 'Oni-Sys: Сводка погоды в стиле Они'
    set -l c_red (set_color -o red)
    set -l c_mag (set_color -o magenta)
    set -l c_reset (set_color normal)

    echo -n $c_mag; echo "--- ONI-SYS :: ДЕМОНИЧЕСКИЙ СИНОПТИК ---"; echo -n $c_reset
    echo ""

    # Запрашиваем текущую погоду в компактном формате
    set -l weather_data (curl -s --max-time 4 "wttr.in/Chita?format=3" 2>/dev/null)

    if test -n "$weather_data"
        echo "  $c_red◆ Погода в Чите сегодня:$c_reset"
        echo "  $weather_data"
    else
        echo "  $c_red◆ Ошибка:$c_reset Не удалось связаться с духами погоды."
    end
    echo ""
end
