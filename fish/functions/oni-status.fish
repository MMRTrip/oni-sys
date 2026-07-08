function oni-status --description 'Oni-Sys RPG-Style Resource Monitor'
    set -l c_red (set_color -o red)
    set -l c_blood (set_color brred)
    set -l c_dark (set_color brblack)
    set -l c_mag (set_color -o magenta)
    set -l c_reset (set_color normal)

    # Функция для отрисовки кастомного статус-бара
    function draw_bar
        set -l val $argv
        set -l max_blocks 20
        set -l filled (math -s0 "$val * $max_blocks / 100")
        set -l empty (math -s0 "$max_blocks - $filled")

        set -l color (set_color -o red)
        if test $val -gt 85
            set color (set_color -o brred)
        else if test $val -lt 40
            set color (set_color brblack)
        end

        echo -n "$color"
        for i in (seq 1 $filled 2>/dev/null)
            echo -n "█"
        end
        echo -n (set_color brblack)
        for i in (seq 1 $empty 2>/dev/null)
            echo -n "░"
        end
        echo -n "$c_reset"
    end

    while true
        # Первым делом полностью очищаем экран для нового кадра (убирает спам)
        clear

        echo "$c_mag""[ ONI-SYS :: REALTIME RESOURCE MONITOR ]""$c_reset"
        echo "$c_dark""Нажмите Ctrl+C для выхода""$c_reset"
        echo ""

        # 1. Расчет CPU
        set -l cpu_load (top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}' | cut -d'.' -f1)
        if test -z "$cpu_load"; set cpu_load 0; end

        set -l cpu_temp ""
        if test -f /sys/class/thermal/thermal_zone0/temp
            set -l raw_temp (cat /sys/class/thermal/thermal_zone0/temp)
            set cpu_temp " ("(math "$raw_temp / 1000")"°C)"
        end

        # 2. Расчет RAM
        set -l ram_data (free -m | awk '/Mem:/ {print $3,$2}')
        set -l ram_used (echo $ram_data | cut -d' ' -f1)
        set -l ram_total (echo $ram_data | cut -d' ' -f2)
        set -l ram_pct (math -s0 "$ram_used * 100 / $ram_total")

        # 3. Расчет GPU
        set -l gpu_pct 0
        set -l gpu_name "GPU"
        if command -v nvidia-smi > /dev/null
            set gpu_pct (nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | string trim)
            set gpu_name "NVIDIA"
        else if test -d /sys/class/drm/card0/device/gpu_busy_percent
            set gpu_pct (cat /sys/class/drm/card0/device/gpu_busy_percent)
            set gpu_name "AMD"
        else if command -v intel_gpu_top > /dev/null
            set gpu_name "INTEL"
        end
        if test -z "$gpu_pct"; set gpu_pct 0; end

        # Вывод интерфейса Oni-Sys
        echo "  $c_blood""[ СИЛА ПРОЦЕССОРА ]""$c_reset"
        echo -n "  "
        draw_bar $cpu_load
        echo " $cpu_load%$cpu_temp"
        echo ""

        echo "  $c_blood""[ ДЕМОНИЧЕСКАЯ ПАМЯТЬ ]""$c_reset"
        echo -n "  "
        draw_bar $ram_pct
        echo " $ram_used / $ram_total MiB ($ram_pct%)"
        echo ""

        echo "  $c_blood""[ ЯДРО ОНИ - $gpu_name ]""$c_reset"
        echo -n "  "
        draw_bar $gpu_pct
        echo " $gpu_pct%"

        sleep 1
    end
end
