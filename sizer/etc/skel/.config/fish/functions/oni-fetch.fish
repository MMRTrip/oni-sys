function oni-fetch --description 'Oni-Sys Bottom System Fetch'
    set -l c_red (set_color -o red)
    set -l c_mag (set_color -o magenta)
    set -l c_dark (set_color brblack)
    set -l c_reset (set_color normal)
    set -l user_host (string upper "$USER@$hostname")
    set -l kernel (uname -r)
    set -l uptime (uptime -p | string replace "up " "")
    set -l pkgs (pacman -Q | count)
    set -l ram_info (free -m | awk '/Mem:/ {print $3,$2}')
    set -l ram_used (echo $ram_info | cut -d' ' -f1)
    set -l ram_total (echo $ram_info | cut -d' ' -f2)
    set -l fish_v (echo $FISH_VERSION | cut -d'-' -f1)
    set -l mem_pct (math "round ($ram_used / $ram_total * 100)")
    set -l filled_slots (math "round ($mem_pct / 10)")
    set -l hp_bar ""
    for i in (seq 1 10)
        if test $i -le $filled_slots
            set hp_bar "$hp_bar"(set_color red)"█"
        else
            set hp_bar "$hp_bar"(set_color brblack)"░"
        end
    end
    echo "                      "$c_mag"══ ONI SYSTEM DATA ══"$c_reset
    echo "  "$c_red"┌────────────────────────────────────────────────────────┐"$c_reset
    echo "    "$c_dark"HOST:"$c_reset"    "$user_host
    echo "    "$c_dark"KERNEL:"$c_reset"  "$kernel
    echo "    "$c_dark"UPTIME:"$c_reset"  "$uptime
    echo "    "$c_dark"PACKAGES:"$c_reset""$pkgs" (pacman)"
    echo "    "$c_dark"SHELL:"$c_reset"   Fish "$fish_v
    echo "    "$c_dark"MEMORY:"$c_reset"  "$ram_used"MiB / "$ram_total"MiB"
    echo -n "    "$c_dark"RAM HP:"$c_reset"  "
    echo -n $c_dark"⟨"$c_reset$hp_bar$c_dark"⟩"$c_reset" "
    echo -n $mem_pct
    echo "%"
    echo "  "$c_red"└────────────────────────────────────────────────────────┘"$c_reset
    echo -n "    "
    for col in (set_color -b black) (set_color -b red) (set_color -b brred) (set_color -b magenta) (set_color -b brmagenta) (set_color -b normal)
        echo -n "$col      "
    end
    echo "$c_reset"
    echo ""
end
