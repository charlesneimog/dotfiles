dbus-update-activation-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
gsettings set org.gnome.desktop.interface cursor-size 24
gsettings set org.gnome.desktop.interface cursor-theme vimix-cursors
gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3'
gsettings set org.gnome.desktop.interface color-scheme 'default'
bash -c "'$HOME/.config/sway/scripts/get_bing_image.sh' && swaybg -i '$HOME/.config/sway/wallpapers/wallpaper.jpg'"
