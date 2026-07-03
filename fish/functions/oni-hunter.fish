function oni-hunter --description 'Oni-Sys: Охота на пожирателей RAM и уничтожение лагов'
    set -l c_red (set_color -o red)
    set -l c_blood (set_color brred)
    set -l br_black (set_color brblack)
    set -l c_mag (set_color -o magenta)
    set -l c_reset (set_color normal)

    echo -n $c_mag; echo "--- ONI-SYS :: ОХОТА НА ПОЖИРАТЕЛЕЙ ПАМЯТИ ---"; echo -n $c_reset
    echo ""

    # Вытаскиваем ТОЛЬКО два поля: PID и %MEM самого жирного процесса
    # Сортируем по памяти, убираем заголовок и забираем самую верхнюю строчку
    set -l top_line (ps -eo pid,%mem --sort=-%mem | grep -vE "PID" | head -n 1 | string trim)

    # Режем строку по пробелам встроенной магией Fish (работает мгновенно и без сбоев)
    set -l proc_data (string split -r -m 1 " " $top_line)
    set -l proc_pid $proc_data[1]
    set -l proc_ram $proc_data[2]

    if test -z "$proc_pid"
        echo "  $c_red◆ Духи спокойны:$c_reset Тяжелых чужеродных процессов не обнаружено."
        return 0
    end

    # Получаем чистое имя процесса по его PID напрямую из ядра (БЕЗ вайлдкардов!)
    set -l proc_name (cat /proc/$proc_pid/comm 2>/dev/null)

    echo "  $c_blood🎯 Обнаружена цель:$c_reset '$proc_name' [PID: $proc_pid] пожирает $proc_ram% твоей RAM!"
    echo -n $br_black; echo "  Инициирую фазу Ярости Демона..."; echo -n $c_reset
    echo ""

    # Уничтожаем цель точно в яблочко по PID
    if sudo kill -9 $proc_pid 2>/dev/null
        echo -n $c_mag; echo "  [Успех] Сущность '$proc_name' успешно уничтожена!"; echo -n $c_reset
        notify-send "Oni-Sys Hunter" "Процесс $proc_name уничтожен. Освобождено $proc_ram% RAM!" --icon=edit-cut

        # Сбрасываем кэш оперативной памяти
        oni-cleaner
    else
        echo "  $c_red◆ Ошибка:$c_reset Не удалось уничтожить процесс. Проверь права sudo."
    end
    echo ""
end
