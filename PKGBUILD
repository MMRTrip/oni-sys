# Maintainer: Oni-Sys OS Team <https://github.com>
pkgname=oni-system-config
pkgver=1.0.0
pkgrel=1
pkgdesc="Системные конфигурации, дотфайлы и профили оптимизации для Oni-Sys OS"
arch=('any')
url="https://github.com"
license=('GPL3')

# Зависимости, которые pacman установит автоматически вместе с нашим пакетом
depends=('fish' 'zram-generator' 'sddm' 'plasma-desktop' 'dialog' 'parted' 'arch-install-scripts')
source=("git+https://github.com.git")
sha256sums=('SKIP')

package() {
    cd "$srcdir/oni-sys"

    # Создаем чистую структуру папок внутри будущего системного пакета
    mkdir -p "$pkgdir/etc/skel/.config"
    mkdir -p "$pkgdir/etc/sysctl.d"
    mkdir -p "$pkgdir/etc/systemd"
    mkdir -p "$pkgdir/etc/sddm.conf.d"
    mkdir -p "$pkgdir/etc/udev/rules.d"
    mkdir -p "$pkgdir/etc/default"            # <-- ДОБАВЛЕНО ТУТ
    mkdir -p "$pkgdir/usr/share/sddm/themes"

    # 0. Копируем дефолтный конфиг GRUB для Dual Boot
    if [ -d "sizer/etc/default" ]; then        # <-- ДОБАВЛЕНО ТУТ
        cp -r sizer/etc/default/* "$pkgdir/etc/default/" # <-- ДОБАВЛЕНО ТУТ
    fi                                         # <-- ДОБАВЛЕНО ТУТ

    # 1. Копируем системные оптимизации ядра (BFQ, кэш под HDD)
    if [ -d "sizer/etc/sysctl.d" ]; then
        cp -r sizer/etc/sysctl.d/* "$pkgdir/etc/sysctl.d/"
    fi

    # 1b. Копируем правила udev для планировщиков диска
    if [ -d "sizer/etc/udev/rules.d" ]; then
        cp -r sizer/etc/udev/rules.d/* "$pkgdir/etc/udev/rules.d/"
    fi

    # 2. Копируем настройки ZRAM (генератор zstd)
    if [ -d "sizer/etc/systemd" ]; then
        cp -r sizer/etc/systemd/* "$pkgdir/etc/systemd/"
    fi

    # 3. Копируем конфигурацию активации темы SDDM
    if [ -d "sizer/etc/sddm.conf.d" ]; then
        cp -r sizer/etc/sddm.conf.d/* "$pkgdir/etc/sddm.conf.d/"
    fi

    # 4. Копируем саму красно-черную тему SDDM в системную директорию
    if [ -d "sizer/usr/share/sddm/themes" ]; then
        cp -r sizer/usr/share/sddm/themes/* "$pkgdir/usr/share/sddm/themes/"
    fi

    # 5. Копируем пользовательские дотфайлы (Fish, KDE хоткеи, разметку стола, автостарт)
    if [ -d "sizer/etc/skel/.config" ]; then
        cp -r sizer/etc/skel/.config/* "$pkgdir/etc/skel/.config/"
    fi

    # Выставляем безопасные и правильные права доступа для шаблона пользователя
    find "$pkgdir/etc/skel" -type d -exec chmod 755 {} +
    find "$pkgdir/etc/skel" -type f -exec chmod 644 {} +
}
