#!/usr/bin/env fish

# Фирменная красно-черная палитра Nakiri Ayame (Акцент #ff2a5f)
set -g COLOR_ONI "ff2a5f"
set -g set_color_oni (set_color $COLOR_ONI)
set -g set_color_success (set_color 00ff7f)
set -g set_color_info (set_color 00bfff)
set -g set_color_normal (set_color normal)

# Проверка и установка утилиты диалоговых окон dialog в среде Live-ISO
if not command -v dialog >/dev/null 2>&1
    sudo pacman -Sy --noconfirm dialog >/dev/null 2>&1
end

# Системные функции логирования в консоль
function log_info
    echo -e "[$set_color_infoINFO$set_color_normal] $argv"
end

function log_success
    echo -e "[$set_color_oniONI-SYS$set_color_normal] $set_color_success$argv$set_color_normal"
end

function log_error
    echo -e "[$set_color_oniERROR$set_color_normal] $argv"
    exit 1
end

# Шаг 1: Приветственное TUI окно дистрибутива
function tui_welcome
    dialog --title " Oni-Sys OS Core Installer " \
    --backtitle "Nakiri Ayame Production Environment | Senior OS Architect" \
    --msgbox "Добро пожаловать в официальный установщик операционной системы Oni-Sys OS.\n\nЭтот мастер поможет вам развернуть полностью оптимизированное окружение на базе Arch Linux для слабых ПК (4GB RAM, медленный HDD).\n\nСистема поддерживает установку в режиме Dual Boot рядом с Windows без потери ваших личных данных." 16 65
end

# Шаг 2: Диалог выбора целевого жесткого диска или SSD
function tui_select_disk
    set -l dialog_args --title " Выбор накопителя " --menu "Выберите целевой диск для установки Oni-Sys OS:" 15 60 5

    # Динамически собираем список подключенных накопителей
    set -l menu_items
    for line in (lsblk -dno NAME,SIZE,MODEL | string match -r '^sd.*|^nvme.*|^hd.*')
        set -l parts (string split -m 2 ' ' (string trim $line))
        set -a menu_items $parts[1]
        set -a menu_items (string join ' ' $parts[2..-1])
    end

    if test (count $menu_items) -eq 0
        log_error "Доступные жесткие диски не обнаружены в системе!"
    end

    set -g TARGET_DISK (dialog $dialog_args $menu_items 2>&1 >/dev/devtty)
    if test -z "$TARGET_DISK"
        log_error "Установка прервана пользователем в меню выбора диска."
    end
    set -g TARGET_DISK "/dev/$TARGET_DISK"
end

# Шаг 3: Выбор стратегии разметки (Чистая установка или Dual Boot)
function tui_select_strategy
    set -l dialog_args --title " Режим разметки накопителя " --menu "Выберите метод разметки для диска $TARGET_DISK:" 15 65 3
    set -g INSTALL_MODE (dialog $dialog_args \
        "DUALBOOT" "Установить рядом с Windows (Безопасно для разделов NTFS)" \
        "CLEAN" "Стереть весь диск полностью и установить только Oni-Sys OS" 2>&1 >/dev/devtty)

    if test -z "$INSTALL_MODE"
        log_error "Установка прервана пользователем в меню выбора стратегии."
    end
end
# Шаг 4: Выполнение разметки и умного форматирования диска
function prepare_partitions
    log_info "Подготовка дисковой разметки на накопителе $TARGET_DISK..."

    if test "$INSTALL_MODE" = "CLEAN"
        # Защитный диалог полной очистки
        dialog --title " КРИТИЧЕСКИЙ ШАГ И ПРЕДУПРЕЖДЕНИЕ " --yesno "Вы выбрали режим CLEAN. Все существующие разделы и данные на диске $TARGET_DISK будут безвозвратно УДАЛЕНЫ. Вы уверены, что хотите продолжить?" 12 60
        if test $status -ne 0; log_error "Установка отменена пользователем."; end

        log_info "Создание новой таблицы разделов GPT..."
        sudo parted -s $TARGET_DISK mklabel gpt

        log_info "Создание системного EFI-раздела..."
        sudo parted -s $TARGET_DISK mkpart primary fat32 1MiB 501MiB
        sudo parted -s $TARGET_DISK set 1 esp on

        log_info "Создание корневого раздела (EXT4)..."
        sudo parted -s $TARGET_DISK mkpart primary ext4 501MiB 100%

        # Вычисляем правильные суффиксы для NVMe и SATA накопителей
        set -g EFI_PART ""
        set -g ROOT_PART ""
        if string match -r "nvme" $TARGET_DISK
            set EFI_PART "$TARGET_DISK"p1
            set ROOT_PART "$TARGET_DISK"p2
        else
            set EFI_PART "$TARGET_DISK"1
            set ROOT_PART "$TARGET_DISK"2
        end

        log_info "Форматирование созданных разделов диска..."
        sudo mkfs.vfat -F32 $EFI_PART >/dev/null
        sudo mkfs.ext4 -F -F $ROOT_PART >/dev/null

    else
        # Режим DUALBOOT - Полная безопасность Windows
        set -l dialog_args --title " Безопасный выбор раздела Linux " --menu "Выберите заранее подготовленный ПУСТОЙ раздел для Oni-Sys OS.\n\nРазделы с Windows (ntfs / bitlocker) выбирать ЗАПРЕЩЕНО!" 18 70 6

        set -l menu_items
        for line in (lsblk -rno NAME,SIZE,FSTYPE $TARGET_DISK)
            set -l parts (string split ' ' $line)
            # Фильтруем служебные строки без размера
            if test (count $parts) -ge 2
                set -a menu_items "/dev/$parts[1]"
                set -a menu_items "Размер: $parts[2] | ФС: $parts[3]"
            end
        end

        if test (count $menu_items) -eq 0
            log_error "На выбранном диске не найдено подходящих разделов для Dual Boot!"
        end

        set -g ROOT_PART (dialog $dialog_args $menu_items 2>&1 >/dev/devtty)
        if test -z "$ROOT_PART"; log_error "Разметка отменена пользователем."; end

        # КРИТИЧЕСКИЙ РУБЕЖ ЗАЩИТЫ: Блокируем форматирование Windows разделов
        set -l check_fs (lsblk -no FSTYPE $ROOT_PART | string trim)
        if string match -qi "*ntfs*" $check_fs; or string match -qi "*bitlocker*" $check_fs
            dialog --title " КРИТИЧЕСКАЯ ОШИБКА БЕЗОПАСНОСТИ " --msgbox "Действие заблокировано!\n\nВы выбрали раздел Windows ($ROOT_PART с файловой системой $check_fs).\n\nУстановщик Oni-Sys OS принудительно прерывает работу, чтобы защитить ваши личные файлы и Windows. Подготовьте пустой EXT4 или unformatted раздел перед запуском." 15 65
            log_error "Попытка форматирования раздела Windows была успешно предотвращена."
        end

        # Автоматический поиск уже существующего EFI-раздела Windows для GRUB
        set -g EFI_PART (lsblk -rno NAME,FSTYPE $TARGET_DISK | grep -i 'vfat' | awk '{print "/dev/"$1}' | head -n 1)
        if test -z "$EFI_PART"
            log_error "Системный EFI-раздел Windows (FAT32) не обнаружен. Автоматический Dual Boot невозможен."
        end

        dialog --title " Подтверждение операции " --yesno "Выделенный раздел $ROOT_PART будет отформатирован под Oni-Sys OS.\n\nСистемный раздел Windows ($EFI_PART) НЕ будет форматироваться, на него лишь аккуратно добавится загрузчик.\n\nВы уверены, что хотите продолжить?" 14 65
        if test $status -ne 0; log_error "Установка прервана пользователем."; end

        log_info "Форматирование выделенного Linux-раздела в EXT4..."
        sudo mkfs.ext4 -F -F $ROOT_PART >/dev/null
    end
end

# Шаг 5: Монтирование разделов и развертывание базовой системы через pacstrap
function bootstrap_base_system
    log_info "Размонтирование возможных старых точек монтирования..."
    sudo umount -R /mnt >/dev/null 2>&1

    log_info "Монтирование корневой файловой системы в /mnt..."
    sudo mount $ROOT_PART /mnt

    log_info "Создание папки загрузчика и монтирование EFI-раздела..."
    sudo mkdir -p /mnt/boot
    sudo mount $EFI_PART /mnt/boot

    log_info "Развертывание базового ядра Arch Linux и утилит (pacstrap)..."
    log_info "На медленном HDD этот процесс может занять 5-10 минут. Пожалуйста, подождите..."

    # Устанавливаем минимальный стек, необходимый для старта окружения и сети
    if not sudo pacstrap -K /mnt base linux-lts linux-firmware fish git sudo networkmanager >/dev/null
        log_error "Произошла критическая ошибка при выполнении утилиты pacstrap."
    end

    log_info "Генерация системной таблицы монтирования дисков fstab..."
    sudo genfstab -U /mnt | sudo tee /mnt/etc/fstab >/dev/null
    log_success "Базовые файлы операционной системы успешно развернуты на диск."
end
# Шаг 6а: Генерация изолированного оркестратора для chroot
function generate_chroot_script
    log_info "Генерация chroot-скрипта автоматизации..."

    set -l chroot_path "/mnt/tmp/oni-chroot.fish"
    sudo mkdir -p /mnt/tmp/oni-sys-installer

    # Копируем наши исходники (пакеты, PKGBUILD, sizer/) внутрь новой системы
    sudo cp -r $WORK_DIR/* /mnt/tmp/oni-sys-installer/

    # Записываем чистый fish-код во временный файл внутри /mnt
    echo "#!/usr/bin/env fish
    set -g WORK_DIR '/tmp/oni-sys-installer'

    echo '=== Этап 1: Обновление pacman и установка базы пакетов ==='
    pacman -Sy --noconfirm
    set -l list_file \"\$WORK_DIR/packages/pacman-list.txt\"
    set -l pkgs (string match -r -v '^\s*#|^\s*\$' < \$list_file)
    pacman -S --noconfirm --needed \$pkgs

    echo '=== Этап 2: Интеллектуальное сканирование видеокарт Nvidia ==='
    if lspci | grep -qi 'Nvidia'
        pacman -S --noconfirm --needed nvidia-lts nvidia-utils lib32-nvidia-utils
    end

    echo '=== Этап 3: Развертывание AUR-помощника yay-bin ==='
    set -l build_dir '/tmp/yay_build'
    mkdir -p \$build_dir
    chown -R nobody:nobody \$build_dir
    sudo -u nobody git clone https://archlinux.org \$build_dir/yay-bin
    cd \$build_dir/yay-bin
    sudo -u nobody makepkg -si --noconfirm
    cd \$WORK_DIR

    echo '=== Этап 4: Установка программ пользователя из AUR ==='
    set -l aur_list \"\$WORK_DIR/packages/aur-list.txt\"
    if test -f \$aur_list
        set -l aur_pkgs (string match -r -v '^\s*#|^\s*\$' < \$aur_list)
        if test -n \"\$aur_pkgs\"
            sudo -u nobody yay -S --noconfirm --needed \$aur_pkgs
        end
    end

    echo '=== Этап 5: Локальная сборка и деплой мета-пакета oni-system-config ==='
    chown -R nobody:nobody \$WORK_DIR
    sudo -u nobody makepkg -si --noconfirm

    echo '=== Этап 6: Настройка загрузчика GRUB и os-prober (Dual Boot) ==='
    pacman -S --noconfirm --needed grub os-prober ntfs-3g
    if test -d /sys/firmware/efi
        pacman -S --noconfirm --needed efibootmgr
        grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=OniSysOS --recheck
    else
        set -l r_drive (lsblk -no pkname (findmnt -nvo SOURCE /))
        if test -z \"\$r_drive\"; set r_drive 'sda'; end
        grub-install --target=i386-pc /dev/\$r_drive --recheck
    end
    grub-mkconfig -o /boot/grub/grub.cfg

    echo '=== Этап 7: Активация оптимизаций слабого ПК и служб ==='
    systemctl enable sddm.service
    systemctl enable NetworkManager.service
    systemctl enable systemd-zram-generator.service
    " | sudo tee $chroot_path >/dev/null

    sudo chmod +x $chroot_path
end

# Шаг 6б: Вход в chroot и запуск выполнения конфигурации
function deploy_onisys_configs
    log_info "Вход в изолированное chroot окружение Oni-Sys OS..."

    # Генерация временного скрипта с помощью шага 6а
    generate_chroot_script

    # Выполняем скрипт внутри новой ОС через arch-chroot
    if not sudo arch-chroot /mnt fish /tmp/oni-chroot.fish
        log_error "Произошла критическая ошибка внутри окружения arch-chroot."
    end

    # Очистка следов автоматизации за собой
    sudo rm -f /mnt/tmp/oni-chroot.fish
end

# Шаг 7: Создание аккаунта пользователя в диалоговом окне
function tui_create_user
    set -l username (dialog --title " Настройка пользователя " --inputbox "Введите имя вашего нового пользователя (латиницей, маленькими буквами):" 10 50 2>&1 >/dev/devtty)
    if test -z "$username"; set username "oniuser"; end

    # Создаем пользователя, копируя дотфайлы (Fish, KDE) из нашего /etc/skel
    sudo arch-chroot /mnt useradd -m -G wheel -s /usr/bin/fish $username

    # Задаем дефолтные пароли для первой загрузки
    echo "$username:1234" | sudo arch-chroot /mnt chpasswd
    echo "root:1234" | sudo arch-chroot /mnt chpasswd

    dialog --title " Установка завершена! " --msgbox "Полноценная Oni-Sys OS успешно установлена!\n\nИмя пользователя: $username\nПароль пользователя: 1234\nПароль root: 1234\n\nИзмените пароли командой 'passwd' после первой загрузки.\n\nСейчас система размонтируется и ПК перезагрузится." 15 60
end

# Главный оркестратор TUI-инсталлятора
function main
    tui_welcome
    tui_select_disk
    tui_select_strategy

    # Подготовка и клонирование манифеста дистрибутива с GitHub
    set -g WORK_DIR "/tmp/oni-sys-installer"
    rm -rf $WORK_DIR; mkdir -p $WORK_DIR
    log_info "Синхронизация манифеста Oni-Sys с репозитория..."
    git clone --depth 1 "https://github.com" $WORK_DIR >/dev/null 2>&1

    # Последовательное выполнение фаз установки
    prepare_partitions
    bootstrap_base_system
    deploy_onisys_configs
    tui_create_user

    # Размонтирование накопителей и перезагрузка
    log_info "Завершение установки, размонтирование разделов диска..."
    sudo umount -R /mnt
    log_info "Перезагрузка ПК через 3 секунды..."
    sleep 3
    sudo reboot
end

# Передача аргументов в точку входа
main $argv
