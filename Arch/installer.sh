# ──────────────────────────────────────
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
#│           Version Control            │
#╰──────────────────────────────────────╯
sudo pacman -S --noconfirm git
sudo pacman -S --noconfirm github-cli
gh auth login

#╭──────────────────────────────────────╮
#│           System Utilities           │
#╰──────────────────────────────────────╯
packages=("power-profiles-daemon" "zsh" "flatpak" "gnome-tweaks" "xsel" "cronie" "ufw" "wget" "jq" "pass" "bluez" "bluez-utils" "blueman")

for package in "${packages[@]}"; do
    install_package "$package"
done

#╭──────────────────────────────────────╮
#│     Programming and Development      │
#╰──────────────────────────────────────╯
packages=("nodejs" "npm" "neovim" "ffmpeg" "python-pip" "base-devel" "jre-openjdk")

for package in "${packages[@]}"; do
    install_package "$package"
done

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
packages=("texlive-langportuguese" "texlive-basic" "texlive-bin" "texlive-binextra" "texlive-fontsrecommended" "texlive-latexrecommended" "texlive-latexextra" "ocrmypdf")

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
#│        OCR and Language Data         │
#╰──────────────────────────────────────╯
packages=("tesseract" "tesseract-data-eng" "tesseract-data-por")
for package in "${packages[@]}"; do
    install_package "$package"
done

#╭──────────────────────────────────────╮
#│            Configurations            │
#╰──────────────────────────────────────╯
sudo ufw enable
sudo systemctl enable ufw
sudo systemctl enable bluetooth.service

#╭──────────────────────────────────────╮
#│             Install Paru             │
#╰──────────────────────────────────────╯
git clone https://aur.archlinux.org/paru.git
cd paru && makepkg -si --noconfirm && cd ..

#╭──────────────────────────────────────╮
#│              Miniconda               │
#╰──────────────────────────────────────╯
mkdir -p ~/.config/miniconda3.dir
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/.config/miniconda3.dir/miniconda.sh
bash ~/.config/miniconda3.dir/miniconda.sh -b -u -p ~/.config/miniconda3.dir
rm -rf ~/.config/miniconda3.dir/miniconda.sh
~/.config/miniconda3.dir/bin/conda init bash
~/.config/miniconda3.dir/bin/conda init zsh

#╭──────────────────────────────────────╮
#│    Open Pd Patches with plugdata     │
#╰──────────────────────────────────────╯
echo "[Default Applications]\ntext/x-puredata=plugdata.desktop" > ~/.local/share/applications/defaults.list

#╭──────────────────────────────────────╮
#│               PACKAGES               │
#╰──────────────────────────────────────╯
packages=("sonic-visualiser" "muse-sounds-manager-bin" "ttf-dejavu-ib" "ttf-times-new-roman" "ttf-jetbrains-mono-nerd" "onedriver" "zathura-pdf-mupdf-git" "intel-ucode")

for package in "${packages[@]}"; do
    paru_install_package "$package"
done

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
#│            Nvim Packages             │
#╰──────────────────────────────────────╯
packages=("clangd" "fd" "flake8")

for package in "${packages[@]}"; do
    paru_install_package "$package"
done

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
sudo cp ~/.config/nvim/Scripts/checkupdates /usr/bin/checkupdates
sudo cp ~/.config/nvim/Scripts/git-updates /usr/bin/git-updates
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
sudo cp ~/.config/nvim/Scripts/notitranslation /usr/bin/

#╭──────────────────────────────────────╮
#│              Mime types              │
#╰──────────────────────────────────────╯
sudo cp ~/.config/nvim/Arch/icons/*.svg /usr/share/icons/
sudo cp ~/.config/nvim/Arch/mime/Overrides.xml /usr/share/mime/packages/

#╭──────────────────────────────────────╮
#│              FlatPacks               │
#╰──────────────────────────────────────╯
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo --user
packages = ("org.zotero.Zotero" "com.github.flxzt.rnote" "com.github.maoschanz.drawing" "com.github.tchx84.Flatseal" "de.haeckerfelix.Fragments" "com.mattjakeman.ExtensionManager" "org.gnome.Evince" "org.kde.okular" "org.libreoffice.LibreOffice" "org.pipewire.Helvum" "org.shotcut.Shotcut" "org.zotero.Zotero" "com.obsproject.Studio" "io.github.shiftey.Desktop" "org.gimp.GIMP")

for package in "${packages[@]}"; do
    flatpak_install_package "$package"
done

flatpak install org.gtk.Gtk3theme.adw-gtk3 org.gtk.Gtk3theme.adw-gtk3-dark -y --user

#╭──────────────────────────────────────╮
#│                Clear                 │
#╰──────────────────────────────────────╯
rm -drf paru
rm -drf ~/go

#╭──────────────────────────────────────╮
#│              UNINSTALL               │
#╰──────────────────────────────────────╯
packages=("gnome-connections" "gnome-characters" "gnome-color-manager" "gnome-contacts" "gnome-font-viewer" "gnome-remote-desktop" "gnome-software" "gnome-tour" "gnome-user-share")

for package in "${packages[@]}"; do
    sudo pacman -R "$package" --noconfirm
done

#╭──────────────────────────────────────╮
#│            Create Symlink            │
#╰──────────────────────────────────────╯

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

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

link_files "$SCRIPT_DIR/../Config/home" "$HOME" true

link_files "$SCRIPT_DIR/../Config/nvim" "$HOME/.config/nvim" false
link_files "$SCRIPT_DIR/../Config/hypr" "$HOME/.config/hypr" false
link_files "$SCRIPT_DIR/../Config/rofi" "$HOME/.config/rofi" false
link_files "$SCRIPT_DIR/../Config/waybar" "$HOME/.config/waybar" false
link_files "$SCRIPT_DIR/../Config/zathura" "$HOME/.config/zathura" false
link_files "$SCRIPT_DIR/../Config/swaync" "$HOME/.config/swaync" false 
link_files "$SCRIPT_DIR/../Config/lazygit" "$HOME/.config/lazygit" false
link_files "$SCRIPT_DIR/../Config/swaylock" "$HOME/.config/swaylock" false 


