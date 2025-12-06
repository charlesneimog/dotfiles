link_files() {
    src=$1
    dst=$2

    # Ensure destination root exists
    mkdir -p "$dst" || {
        echo "ERROR: Cannot create directory $dst"
        return 1
    }

    find "$src" -mindepth 1 | while IFS= read -r item; do
        rel=${item#"$src/"}              # relative path
        target="$dst/$rel"               # where it will be linked

        if [ -d "$item" ]; then
            # Create directory in destination
            mkdir -p "$target" || {
                echo "ERROR: Cannot create directory $target"
            }
        else
            # Ensure parent directory exists
            mkdir -p "$(dirname "$target")" || {
                echo "ERROR: Cannot create parent directory for $target"
                continue
            }

            # Remove existing file/dir/symlink
            if [ -e "$target" ] || [ -L "$target" ]; then
                rm -rf "$target" || {
                    echo "ERROR: Cannot remove existing $target"
                    continue
                }
            fi

            # Create symlink
            ln -s "$item" "$target" || {
                echo "ERROR: Failed to link $item → $target"
                continue
            }

            echo "Linked: $item → $target"
        fi
    done
}

#╭──────────────────────────────────────╮
#│            Create Symlink            │
#╰──────────────────────────────────────╯
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

link_files "$SCRIPT_DIR/../config/home" "$HOME" true
link_files "$SCRIPT_DIR/../config/nvim" "$HOME/.config/nvim" false
link_files "$SCRIPT_DIR/../config/rofi/files" "$HOME/.config/rofi" false
link_files "$SCRIPT_DIR/../config/waybar" "$HOME/.config/waybar" false
link_files "$SCRIPT_DIR/../config/zathura" "$HOME/.config/zathura" false
link_files "$SCRIPT_DIR/../config/swaync" "$HOME/.config/swaync" false 
link_files "$SCRIPT_DIR/../config/sway" "$HOME/.config/sway" false 
link_files "$SCRIPT_DIR/../config/hypr" "$HOME/.config/hypr" false 
link_files "$SCRIPT_DIR/../config/lazygit" "$HOME/.config/lazygit" false
link_files "$SCRIPT_DIR/../config/yazi" "$HOME/.config/yazi" false
link_files "$SCRIPT_DIR/../config/swaylock" "$HOME/.config/swaylock" false 
link_files "$SCRIPT_DIR/../config/pipewire" "$HOME/.config/pipewire" false
link_files "$SCRIPT_DIR/../config/formatters" "$HOME/" true 
link_files "$SCRIPT_DIR/../config/plugdata" "$HOME/Documents/plugdata" true 
link_files "$SCRIPT_DIR/../config/niri" "$HOME/.config/niri" false
link_files "$SCRIPT_DIR/../config/ghostty" "$HOME/.config/ghostty" false
