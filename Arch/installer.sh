#╭──────────────────────────────────────╮
#│            Main Functions            │
#╰──────────────────────────────────────╯
install_package() {
    local package="$1"

    # Check if the package is installed
    if ! pacman -Q "$package" &> /dev/null; then
        echo "Installing $package..."
        sudo pacman -S --noconfirm "$package"
    else
        echo "$package is already installed."
    fi
}

# ──────────────────────────────────────
paru_install_package() {
    local package="$1"
    if ! paru -Q "$package" &> /dev/null; then
        echo "Installing $package..."
        paru -S --noconfirm "$package"
    else
        echo "$package is already installed."
    fi
}

# ──────────────────────────────────────
flatpak_install_package() {
    local package="$1"

    # Check if the package is installed
    if ! pacman -Q "$package" &> /dev/null; then
        echo "Installing $package..."
        flatpak install flathub "$package" -y --user
            
    else
        echo "$package is already installed."
    fi
}

# ──────────────────────────────────────
link_files() {
    local source_dir=$1
    local target_dir=$2
    mkdir -p "$target_dir"
    if $3; then
        for file in "$source_dir"/.* "$source_dir"/**/.*; do
            echo $file
            if [ -d "$file" ]; then
                mkdir -p "$target_dir/$(basename "$file")"
                local sub_dir=$(basename "$file")
                link_files "$file" "$target_dir/$sub_dir" true
            else 
                if [ -f "$target_dir/$(basename "$file")" ]; then
                    continue
                fi
                ln -s "$file" "$target_dir/"
            fi
        done
    else
        for file in "$source_dir"/*; do
            echo $file
            if [ -d "$file" ]; then
                mkdir -p "$target_dir/$(basename "$file")"
                local sub_dir=$(basename "$file")
                link_files "$file" "$target_dir/$sub_dir" false
            else 
                if [ -f "$target_dir/$(basename "$file")" ]; then
                    continue
                fi
                ln -s "$file" "$target_dir/"
            fi
        done
    fi
}

#╭──────────────────────────────────────╮
#│         Pacman Configuration         │
#╰──────────────────────────────────────╯
new_config=$(cat <<EOF
[options]
HoldPkg     = pacman glibc
Architecture = auto
Color
CheckSpace
ParallelDownloads = 10
SigLevel    = Required DatabaseOptional
LocalFileSigLevel = Optional
ILoveCandy

[core]
Include = /etc/pacman.d/mirrorlist

[extra]
Include = /etc/pacman.d/mirrorlist
EOF
)

echo "$new_config" | sudo tee /etc/pacman.conf > /dev/null

#╭──────────────────────────────────────╮
cd ~/Downloads/
sudo pacman -S --needed base-devel
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si --noconfirm
sudo paru -Sy --noconfirm brave-bin 

#╭──────────────────────────────────────╮
#│           Version Control            │
#╰──────────────────────────────────────╯

#╭──────────────────────────────────────╮
#│           System Utilities           │
#╰──────────────────────────────────────╯
packages=("power-profiles-daemon" "zsh" "flatpak" "xsel" "cronie" "ufw" "wget" "jq" "pass" "git" "github-cli") 

for package in "${packages[@]}"; do
    install_package "$package"
done

gh auth login

#╭──────────────────────────────────────╮
#│     Programming and Development      │
#╰──────────────────────────────────────╯
packages=("clangd" "fd" "flake8" "cmake" "nodejs" "npm" "neovim" "ffmpeg" "python-pip" "base-devel" "jre-openjdk" "lua-check" "lazygit")

for package in "${packages[@]}"; do
    install_package "$package"
done


for package in "${packages[@]}"; do
    paru_install_package "$package"
done

#╭──────────────────────────────────────╮
#│          Hyprland and Sway           │
#╰──────────────────────────────────────╯
packages=("sway" "hyprland" "sushi" "waybar" "rofi" "hypridle" "swaync" "gsettings" "polkit-gnome" "wl-clipboard" "fzf" "zoxide" "zenity" "hyprpaper" "brightnessctl" "blueman" "nm-connection-editor" "pavucontrol" "wireplumber" "pipewire-jack" "slurp" "grim" "xdg-desktop-portal-hyprland" "xdg-desktop-portal-gtk" "xdg-desktop-portal-wlr" "autotiling-rs" "swayidle" "swaylock" "qt6-svg" "qt6-declarative" "sdmm")

for package in "${packages[@]}"; do
    paru_install_package "$package"
done

sudo systemctl enable sddm.service
sudo cp -r /home/neimog/Documents/Git/dotfiles/Config/sddm/catppuccin-mocha /usr/share/sddm/themes/
sudo bash -c 'echo -e "\n[Theme]\nCurrent=catppuccin-mocha" >> /etc/sddm.conf'
sudo bash -c 'echo -e "\n[Session]\nSession=sway.desktop" >> /etc/sddm.conf'

#╭──────────────────────────────────────╮
#│              Multimedia              │
#╰──────────────────────────────────────╯
packages=("plugdata-bin" "puredata" "ripgrep" "inkscape" "gst-plugins-ugly" "gst-plugins-good" "gst-plugins-bad" "gst-plugins-base" "gst-libav" "gstreamer")

for package in "${packages[@]}"; do
    install_package "$package"
done

#╭──────────────────────────────────────╮
#│   Text Processing and Typesetting    │
#╰──────────────────────────────────────╯
packages=("texlive-langportuguese" "texlive-basic" "texlive-bin" "texlive-binextra" "texlive-fontsrecommended") 

for package in "${packages[@]}"; do
    install_package "$package"
done

#╭──────────────────────────────────────╮
#│     System Firmware and Updates      │
#╰──────────────────────────────────────╯
packages=("fwupd" "power-profiles-daemon")

for package in "${packages[@]}"; do
    install_package "$package"
done

#╭──────────────────────────────────────╮
#│                Fonts                 │
#╰──────────────────────────────────────╯
packages=("otf-san-francisco" "ttf-dejavu-ib" "ttf-times-new-roman" "ttf-jetbrains-mono-nerd" "ttf-meslo" "noto-fonts-emoji")

for package in "${packages[@]}"; do
    paru_install_package "$package"
done

#╭──────────────────────────────────────╮
#│              FlatPacks               │
#╰──────────────────────────────────────╯
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo --user
packages = ("flatpak install flathub org.gnome.TextEditor" "org.gtk.Gtk3thme.adw-gtk3" "org.gtk.Gtk3theme.adw-gtk3-dark" "org.zotero.Zotero" "com.github.flxzt.rnote" "org.kde.okular" "org.libreoffice.LibreOffice" "org.pipewire.Helvum" "org.shotcut.Shotcut" "org.zotero.Zotero" "com.obsproject.Studio" "org.gnome.Calculator" "org.gnome.Totem" "org.gnome.baobab")

for package in "${packages[@]}"; do
    flatpak_install_package "$package"
done

#╭──────────────────────────────────────╮
#│               PACKAGES               │
#╰──────────────────────────────────────╯
packages=("sonic-visualiser" "muse-sounds-manager-bin" "intel-ucode")

for package in "${packages[@]}"; do
    paru_install_package "$package"
done

#╭──────────────────────────────────────╮
#│               Servidor               │
#╰──────────────────────────────────────╯
packages=("nextcloud-client" "netbird")

for package in "${packages[@]}"; do
    paru_install_package "$package"
done


#╭──────────────────────────────────────╮
#│    Open Pd Patches with plugdata     │
#╰──────────────────────────────────────╯
echo "[Default Applications]\ntext/x-puredata=plugdata.desktop" > ~/.local/share/applications/defaults.list

#╭──────────────────────────────────────╮
#│                Themes                │
#╰──────────────────────────────────────╯
packages=("adw-gtk-theme")

for package in "${packages[@]}"; do
    paru_install_package "$package"
done

sudo cp -r ./mime/* /usr/share/mime/packages/
sudo update-mime-database /usr/share/mime/
sudo cp -r ./icons/* /usr/share/icons/
git clone https://github.com/vinceliuice/Tela-circle-icon-theme.git
cd Tela-circle-icon-theme && ./install.sh && cd ..
gsettings set org.gnome.desktop.interface icon-theme 'Tela-circle-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3'
rm -drf Tela-circle-icon-theme

#╭──────────────────────────────────────╮
#│               Terminal               │
#╰──────────────────────────────────────╯
chsh -s $(which zsh)
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone git@github.com:charlesneimog/dotfiles.git ~/.config/nvim
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

#╭──────────────────────────────────────╮
#│               Schedule               │
#╰──────────────────────────────────────╯
sudo cp ~/Documents/Git/dotfiles/Scripts/checkupdates /usr/bin/checkupdates
sudo cp ~/Documents/Git/dotfiles/Scripts/git-updates /usr/bin/git-updates
sudo chmod +x /usr/bin/checkupdates
sudo chmod +x /usr/bin/git-updates

systemctl enable --now cronie.service
(crontab -l ; echo "0 9 */3 * * /usr/bin/checkupdates") | crontab -
(crontab -l ; echo "0 17 */3 * * /usr/bin/git-updates") | crontab -

#╭──────────────────────────────────────╮
#│               Scripts                │
#╰──────────────────────────────────────╯
wget git.io/trans
chmod +x ./trans
sudo mv trans /usr/bin/
sudo cp ~/Documents/Scripts/notitranslation /usr/bin/

#╭──────────────────────────────────────╮
#│              Mime types              │
#╰──────────────────────────────────────╯
sudo cp ~/Documents/Git/dotfiles/Arch/icons/*.svg /usr/share/icons/
sudo cp ~/Documents/Git/dotfiles/Arch/mime/Overrides.xml /usr/share/mime/packages/


#╭──────────────────────────────────────╮
#│               Tarefas                │
#╰──────────────────────────────────────╯
crontab -l > current_cron
sed '/---script managed section---/q' current_cron > new_cron

cat >> new_cron << EOF
#---script managed section---
0 9 */3 * * /home/neimog/Documents/Git/dotfiles/Scripts/checkupdates
0 17 */3 * * /home/neimog/Documents/Git/dotfiles/Scripts/git-updates
EOF

crontab < new_cron
rm -f new_cron current_cron

#╭──────────────────────────────────────╮
#│            Configurations            │
#╰──────────────────────────────────────╯
sudo ufw enable
sudo systemctl enable ufw
sudo systemctl enable bluetooth.service
ln -s /usr/bin/nvim /usr/bin/vi

# Miniconda
mkdir -p ~/.config/miniconda3.dir
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/.config/miniconda3.dir/miniconda.sh
bash ~/.config/miniconda3.dir/miniconda.sh -b -u -p ~/.config/miniconda3.dir
rm -rf ~/.config/miniconda3.dir/miniconda.sh
~/.config/miniconda3.dir/bin/conda init bash
~/.config/miniconda3.dir/bin/conda init zsh
rm /home/neimog/.config/miniconda3.dir/bin/wish
ln -s /usr/bin/wish /home/neimog/.config/miniconda3.dir/bin/wish

#╭──────────────────────────────────────╮
#│                Clear                 │
#╰──────────────────────────────────────╯
rm -drf paru
rm -drf ~/go


#╭──────────────────────────────────────╮
#│            Create Symlink            │
#╰──────────────────────────────────────╯

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

link_files "$SCRIPT_DIR/../Config/home" "$HOME" true
link_files "$SCRIPT_DIR/../Config/nvim" "$HOME/.config/nvim" false
link_files "$SCRIPT_DIR/../Config/hypr" "$HOME/.config/hypr" false
link_files "$SCRIPT_DIR/../Config/rofi" "$HOME/.config/rofi" false
link_files "$SCRIPT_DIR/../Config/waybar" "$HOME/.config/waybar" false
link_files "$SCRIPT_DIR/../Config/zathura" "$HOME/.config/zathura" false
link_files "$SCRIPT_DIR/../Config/swaync" "$HOME/.config/swaync" false 
link_files "$SCRIPT_DIR/../Config/lazygit" "$HOME/.config/lazygit" false
link_files "$SCRIPT_DIR/../Config/swaylock" "$HOME/.config/swaylock" false 
link_files "$SCRIPT_DIR/../Config/plugdata" "$HOME/Documents/plugdata" true 


