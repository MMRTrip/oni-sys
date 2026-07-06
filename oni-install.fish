#!/usr/bin/env fish

# Настройка фирменной палитры Nakiri Ayame (Красный акцент #ff2a5f)
set -g COLOR_ONI "ff2a5f"
set -g set_color_oni (set_color $COLOR_ONI)
set -g set_color_success (set_color 00ff7f)
set -g set_color_info (set_color 00bfff)
set -g set_color_normal (set_color normal)

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

# 1. Проверка сетевого соединения
function check_network
    log_info "Проверка сетевого соединения..."
    if not ping -c 1 archlinux.org >/dev/null 2>&1
        log_error "Нет сети. Подключите интернет перед запуском (iwctl для Wi-Fi)."
    end
    log_success "Сетевое соединение активно."
end

# 2. Подготовка окружения и клонирование репозитория
function clone_repository
    set -g REPO_URL "https://github.com"
    set -g WORK_DIR "/tmp/oni-sys-installer"

    log_info "Очистка временных папок..."
    rm -rf $WORK_DIR
    mkdir -p $WORK_DIR

    log_info "Клонирование репозитория дистрибутива с GitHub..."
    if not git clone --depth 1 $REPO_URL $WORK_DIR
        log_error "Не удалось клонировать репозиторий $REPO_URL"
    end
    log_success "Репозиторий успешно синхронизирован."
end

# 3. Установка официальной пакетной базы из твоего бэкапа + Видеостек
function install_pacman_base
    set -l list_file "$WORK_DIR/packages/pacman-list.txt"
    if not test -f $list_file
        log_error "Файл $list_file не найден!"
    end

    log_info "Синхронизация официальных репозиториев Arch Linux..."
    sudo pacman -Sy --noconfirm

    # Считываем пакеты, убирая пустые строки и комментарии
    set -l pkgs (string match -r -v '^\s*#|^\s*$' < $list_file)
    if test -n "$pkgs"
        log_info "Установка программного обеспечения и ядра..."
        sudo pacman -S --noconfirm --needed $pkgs
        log_success "Базовые пакеты установлены."
    else
        log_error "Список пакетов pacman-list.txt пуст."
    end

    # --- ИНТЕЛЛЕКТУАЛЬНОЕ ОПРЕДЕЛЕНИЕ И УСТАНОВКА NVIDIA ---
    log_info "Сканирование PCI-шины на наличие GPU Nvidia..."
    if lspci | grep -qi "Nvidia"
        log_info "Обнаружена видеокарта Nvidia! Установка проприетарного драйвера под LTS-ядро..."
        sudo pacman -S --noconfirm --needed nvidia-lts nvidia-utils lib32-nvidia-utils
        log_success "Драйверы Nvidia успешно интегрированы в систему."
    else
        log_info "Видеокарта Nvidia не обнаружена. Используется универсальный открытый видеостек."
    end
end

# 4. Бутстрап Yay (из бинарного пакета для защиты слабого CPU/RAM)
function bootstrap_yay
    if command -v yay >/dev/null 2>&1
        log_info "Yay уже присутствует в системе."
        return
    end

    log_info "Подготовка изолированного окружения для сборки AUR-помощника..."
    set -l build_dir "/tmp/yay_build"
    mkdir -p $build_dir

    # Сборка под root запрещена makepkg, используем системного nobody при установке из ISO
    chown -R nobody:nobody $build_dir

    log_info "Сканирование и загрузка бинарной сборки yay-bin..."
    sudo -u nobody git clone https://archlinux.org $build_dir/yay-bin

    cd $build_dir/yay-bin
    log_info "Компиляция и интеграция yay-bin в систему..."
    if not sudo -u nobody makepkg -si --noconfirm
        log_error "Сбой при установке yay-bin."
    end

    cd $WORK_DIR
    log_success "Помощник Yay успешно развернут."
end

# 5. Установка AUR-пакетов из твоих списков программ
function install_aur_base
    set -l list_file "$WORK_DIR/packages/aur-list.txt"
    if not test -f $list_file
        log_info "Файл aur-list.txt отсутствует или пуст. Пропускаем AUR."
        return
    end

    set -l aur_pkgs (string match -r -v '^\s*#|^\s*$' < $list_file)
    if test -n "$aur_pkgs"
        log_info "Установка пользовательских программ из AUR..."
        # Запуск идет без sudo, yay сам запросит пароль при необходимости
        yay -S --noconfirm --needed $aur_pkgs
        log_success "Все AUR пакеты успешно развернуты."
    end
end

# 6. Сборка локального мета-пакета конфигурации Oni-Sys
function install_oni_meta_package
    log_info "Сборка локального мета-пакета конфигурации oni-system-config..."
    cd $WORK_DIR

    # Собираем и ставим наш PKGBUILD, который раскидает папки из sizer/ в систему
    if not makepkg -si --noconfirm
        log_error "Критическая ошибка сборки мета-пакета конфигурации."
    end
    log_success "Глобальные системные файлы и профили настроек установлены."
    end

        # 6b. Автоматическое определение архитектуры и настройка GRUB
function configure_grub
    log_info "Подготовка и настройка загрузчика GRUB..."

    # Проверяем, в каком режиме загружена система (UEFI или BIOS)
    if test -d /sys/firmware/efi
        log_info "Обнаружен режим UEFI. Настройка GRUB для EFI..."

        # Доставляем необходимые пакеты для UEFI, если их нет
        sudo pacman -S --noconfirm --needed grub efibootmgr

        # Устанавливаем GRUB для UEFI
        if not sudo grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=OniSysOS --recheck
            log_error "Сбой при установке GRUB в режиме UEFI."
        end
    else
        log_info "Обнаружен режим Legacy BIOS. Настройка GRUB..."

        # Для Legacy BIOS нам нужно знать целевой диск (например, sda или sdb)
        # Автоматически находим корневой диск системы
        set -l root_drive (lsblk -no pkname (findmnt -nvo SOURCE /))

        if test -z "$root_drive"
            # Еслиlsblk не вернул родительский диск, берем первый попавшийся sda в качестве безопасного фолбека
            set root_drive "sda"
        end

        log_info "Установка GRUB на диск /dev/$root_drive..."
        sudo pacman -S --noconfirm --needed grub

        if not sudo grub-install --target=i386-pc /dev/$root_drive --recheck
            log_error "Сбой при установке GRUB в режиме Legacy BIOS."
        end
    end

    # Генерируем финальный конфигурационный файл загрузчика
    log_info "Генерация grub.cfg..."
    if not sudo grub-mkconfig -o /boot/grub/grub.cfg
        log_error "Не удалось создать конфигурацию grub.cfg"
    end
    log_success "Загрузчик GRUB успешно настроен и активирован."
end

# 7. Запуск системных демонов и служб оптимизации
function enable_system_services
    log_info "Активация профилей оптимизации и системных служб..."

    # Включаем менеджер дисплея (экран входа) SDDM
    sudo systemctl enable sddm.service

    # Перечитываем конфигурацию systemd и активируем генератор ZRAM
    sudo systemctl daemon-reload
    sudo systemctl enable --now systemd-zram-generator.service

    # Принудительно заставляем ядро применить наши udev-правила (включаем BFQ на HDD)
    sudo udevadm control --reload-rules
    sudo udevadm trigger

    # Применяем оптимизацию кэша страниц sysctl под медленные диски
    sudo sysctl --system

    log_success "Все службы оптимизации запущены."
end

# Точка входа в инсталлятор
function main
    clear
    echo -e "$set_color_oni"
    echo "===================================================="
    echo "             ONI-SYS OS CORE INSTALLER              "
    echo "===================================================="
    echo -e "$set_color_normal"
    log_info "Инициализация процесса развертывания Oni-Sys OS..."

    check_network
    clone_repository
    install_pacman_base
    bootstrap_yay
    install_aur_base
    install_oni_meta_package
    configure_grub
    enable_system_services

    echo -e "\n$set_color_success[УСПЕХ]$set_color_normal Развертывание Oni-Sys OS успешно завершено!"
    echo "1. Задайте root-пароль: passwd root"
    echo "2. Создайте пользователя: useradd -m -G wheel -s /usr/bin/fish имя"
    echo "3. Задайте пароль пользователю: passwd имя"
    echo "Выполните перезагрузку ПК."
end

main $argv
