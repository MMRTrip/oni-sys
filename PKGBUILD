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

    # Создаем полную структуру независимого окружения рабочего стола
    mkdir -p "$pkgdir/etc/skel/.config"
    mkdir -p "$pkgdir/etc/skel/.local/share/color-schemes"
    mkdir -p "$pkgdir/etc/sysctl.d"
    mkdir -p "$pkgdir/etc/systemd"
    mkdir -p "$pkgdir/etc/sddm.conf.d"
    mkdir -p "$pkgdir/etc/udev/rules.d"
    mkdir -p "$pkgdir/etc/default"
    mkdir -p "$pkgdir/usr/share/sddm/themes"
    mkdir -p "$pkgdir/usr/share/xsessions"     # <-- ДОБАВЛЕНО ТУТ

    # Копируем системный сеанс Oni-DE для экрана входа SDDM
    if [ -d "sizer/usr/share/xsessions" ]; then
        cp -r sizer/usr/share/xsessions/* "$pkgdir/usr/share/xsessions/"
    fi

    # Копируем системные конфиги, GRUB и профили оптимизации дисков/памяти
    [ -d "sizer/etc/default" ] && cp -r sizer/etc/default/* "$pkgdir/etc/default/"
    [ -d "sizer/etc/sysctl.d" ] && cp -r sizer/etc/sysctl.d/* "$pkgdir/etc/sysctl.d/"
    [ -d "sizer/etc/udev/rules.d" ] && cp -r sizer/etc/udev/rules.d/* "$pkgdir/etc/udev/rules.d/"
    [ -d "sizer/etc/systemd" ] && cp -r sizer/etc/systemd/* "$pkgdir/etc/systemd/"
    [ -d "sizer/etc/sddm.conf.d" ] && cp -r sizer/etc/sddm.conf.d/* "$pkgdir/etc/sddm.conf.d/"
    [ -d "sizer/usr/share/sddm/themes" ] && cp -r sizer/usr/share/sddm/themes/* "$pkgdir/usr/share/sddm/themes/"

    # Копируем пользовательские дотфайлы (Fish, кастомный KWin, kdeglobals, палитру OniAyame)
    if [ -d "sizer/etc/skel" ]; then
        cp -r sizer/etc/skel/* "$pkgdir/etc/skel/"
    fi

    # Принудительно выставляем безопасные права доступа для шаблона пользователя
    find "$pkgdir/etc/skel" -type d -exec chmod 755 {} +
    find "$pkgdir/etc/skel" -type f -exec chmod 644 {} +
}
