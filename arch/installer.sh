#!/bin/bash

rm -dfr ~/.config/niri
rm -dfr ~/.config/waybar

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
source ./arch/packages.conf
mkdir -p /home/neimog/Downloads

#╭──────────────────────────────────────╮
#│             Install Paru             │
#╰──────────────────────────────────────╯
if ! command -v paru &> /dev/null; then
    echo "Paru não encontrado. Instalando..."
    cd ~/Downloads/ || exit
    sudo pacman -S --needed --noconfirm base-devel git
    git clone https://aur.archlinux.org/paru-bin.git
    cd paru-bin || exit
    makepkg -si --noconfirm
    cd ..
    rm -rf paru-bin
else
    echo "Paru já está instalado."
fi

git config --global user.name "Charles K. Neimog"
git config --global user.email "charlesneimog@outlook.com"

# ╭──────────────────────────────────────╮
# │        Paru and AUR packages         │
# ╰──────────────────────────────────────╯
paru -S --needed --noconfirm "${SYSTEM_UTILS[@]}"
paru -S --needed --noconfirm "${DEV_TOOLS[@]}"
paru -S --needed --noconfirm "${MAINTENANCE[@]}"
paru -S --needed --noconfirm "${DESKTOP[@]}"
paru -S --needed --noconfirm "${MEDIA[@]}"
paru -S --needed --noconfirm "${FONTS[@]}"
paru -S --needed --noconfirm "${TEX_PACKAGES[@]}"
paru -S --needed --noconfirm "${FIRMWARE[@]}"
paru -S --needed --noconfirm "${SERVER_TOOLS[@]}"

#╭──────────────────────────────────────╮
#│             Permissions              │
#╰──────────────────────────────────────╯
sudo chown $USER /sys/class/leds/platform::kbd_backlight/brightness
sudo usermod -aG docker $USER


#╭──────────────────────────────────────╮
#│           FLATPAK packages           │
#╰──────────────────────────────────────╯
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo --user
for app in "${FLATPAKS[@]}"; do
    flatpak install --user --noninteractive flathub "$app"
done

#╭──────────────────────────────────────╮
#│               Services               │
#╰──────────────────────────────────────╯
for service in "${SERVICES[@]}"; do
    sudo systemctl enable "$service"
done

#╭──────────────────────────────────────╮
#│               NetBird                │
#╰──────────────────────────────────────╯
curl -fsSL https://pkgs.netbird.io/install.sh | sh

#╭──────────────────────────────────────╮
#│               Terminal               │
#╰──────────────────────────────────────╯
chsh -s $(which zsh)
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

#╭──────────────────────────────────────╮
#│               Schedule               │
#╰──────────────────────────────────────╯
systemctl enable --now cronie.service

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
#│            Configurations            │
#╰──────────────────────────────────────╯
sudo ufw enable
sudo systemctl enable ufw
sudo systemctl enable bluetooth.service
sudo ln -s /usr/bin/nvim /usr/bin/vi
sudo ln -s /usr/bin/nvim /usr/bin/nano

# ╭──────────────────────────────────────╮
# │              Miniconda               │
# ╰──────────────────────────────────────╯
CONDA_DIR="$HOME/.config/miniconda3.dir"
CONDA_BIN="$CONDA_DIR/bin/conda"

if [ -x "$CONDA_BIN" ]; then
    echo "Miniconda já está instalado em $CONDA_DIR."
else
    echo "Instalando Miniconda..."
    mkdir -p "$CONDA_DIR"
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O "$CONDA_DIR/miniconda.sh"
    bash "$CONDA_DIR/miniconda.sh" -b -u -p "$CONDA_DIR"
    rm -f "$CONDA_DIR/miniconda.sh"

    # Inicializa para bash e zsh
    "$CONDA_BIN" init bash
    "$CONDA_BIN" init zsh

    # Corrige o binário 'wish'
    rm -f "$CONDA_DIR/bin/wish"
    ln -s /usr/bin/wish "$CONDA_DIR/bin/wish"

    echo "Miniconda instalado com sucesso."
fi

#╭──────────────────────────────────────╮
#│                Clear                 │
#╰──────────────────────────────────────╯
rm -drf paru-bin
rm -drf ~/go

#╭──────────────────────────────────────╮
#│            Create Symlink            │
#╰──────────────────────────────────────╯
source ~/Documents/Git/dotfiles/arch/link.sh

#╭──────────────────────────────────────╮
#│           Set Default Apps           │
#╰──────────────────────────────────────╯
xdg-mime default io.bassi.Amberol.desktop audio/x-wav

#╭──────────────────────────────────────╮
#│             Last Configs             │
#╰──────────────────────────────────────╯
gh auth login

#╭──────────────────────────────────────╮
#│                 Mime                 │
#╰──────────────────────────────────────╯
cd ~/Documents/Git/dotfiles
sudo cp -r ./mime/* /usr/share/mime/packages/
sudo update-mime-database /usr/share/mime/
sudo cp -r ./icons/* /usr/share/icons/
git clone https://github.com/vinceliuice/Tela-circle-icon-theme.git
cd Tela-circle-icon-theme && ./install.sh && cd ..
gsettings set org.gnome.desktop.interface icon-theme 'Tela-circle-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3'
rm -drf Tela-circle-icon-theme

#╭──────────────────────────────────────╮
#│         Login and LockScreen         │
#╰──────────────────────────────────────╯
sudo bash -c 'echo -e "[Theme]\nCurrent=catppuccin-mocha-blue" > /etc/sddm.conf.d/theme.conf'
wget -O ~./.avatar.png https://avatars.githubusercontent.com/u/31707161?v=4


