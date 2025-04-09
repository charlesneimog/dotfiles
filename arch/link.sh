#╭──────────────────────────────────────╮
#│              FUNCTIONS               │
#╰──────────────────────────────────────╯
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
                ln -sf "$file" "$target_dir/"
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
                ln -sf "$file" "$target_dir/"
            fi
        done
    fi
}

#╭──────────────────────────────────────╮
#│            Create Symlink            │
#╰──────────────────────────────────────╯
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

link_files "$SCRIPT_DIR/../config/home" "$HOME" true
link_files "$SCRIPT_DIR/../config/nvim" "$HOME/.config/nvim" false
link_files "$SCRIPT_DIR/../config/rofi" "$HOME/.config/rofi" false
link_files "$SCRIPT_DIR/../config/waybar" "$HOME/.config/waybar" false
link_files "$SCRIPT_DIR/../config/zathura" "$HOME/.config/zathura" false
link_files "$SCRIPT_DIR/../config/swaync" "$HOME/.config/swaync" false 
link_files "$SCRIPT_DIR/../config/sway" "$HOME/.config/sway" false 
link_files "$SCRIPT_DIR/../config/lazygit" "$HOME/.config/lazygit" false
link_files "$SCRIPT_DIR/../config/swaylock" "$HOME/.config/swaylock" false 
link_files "$SCRIPT_DIR/../config/formatters" "$HOME/" true 
link_files "$SCRIPT_DIR/../config/plugdata" "$HOME/Documents/plugdata" true 
