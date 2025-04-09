#!/bin/bash

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
