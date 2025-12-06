

# ──────────────────────────────────────
clipboard_rofi() {
    if pgrep -x rofi > /dev/null; then
        killall rofi
    else
        cliphist list | \
            rofi -dmenu -theme "$HOME/.config/rofi/launchers/type-7/style-2.rasi" | \
            cliphist decode | wl-copy
    fi
}

# ──────────────────────────────────────
launch_rofi() {
    if pgrep -x rofi > /dev/null; then
        killall rofi
    else
        rofi -show drun \
             -show-icons \
             -icon-theme 'Tela-circle' \
             -theme "$HOME/.config/rofi/launchers/type-3/style-10.rasi"
    fi
}

# ──────────────────────────────────────
launch_powermenu() {
    bash -c "/home/neimog/.config/rofi/powermenu/type-2/powermenu.sh"
}

# ──────────────────────────────────────
startup_services() {
    export DISPLAY=":0"
    export ELECTRON_OZONE_PLATFORM_HINT="auto"
    export MOZ_ENABLE_WAYLAND="1"
    export QT_QPA_PLATFORMTHEME="qt5ct"
    export QT_QPA_PLATFORM="wayland;xcb"
    export QT_AUTO_SCREEN_SCALE_FACTOR="1"
    export QT_WAYLAND_DISABLE_WINDOW_DECORATION="1"
    export GDK_BACKEND="wayland"
    export XDG_SESSION_TYPE="wayland"
    export XDG_CURRENT_DESKTOP="gnome"
    export XDG_SESSION_DESKTOP="gnome"

    # Custom function
    sh -c "$HOME/.functions.sh unsplash" &

    # Portals
    /usr/lib/xdg-desktop-portal-gtk &
    /usr/lib/xdg-desktop-portal-gnome &

    # Services
    sh -c "wl-paste --type text --watch cliphist store" &
    sh -c "wl-paste --type image --watch cliphist store" &
    sh -c "dbus-update-activation-environment --all" &
    sh -c "gnome-keyring-daemon --start --components=secrets" &

    # Apps
    xwayland-satellite &
    nextcloud &
    anytype &
    blueman-applet &
}

# ──────────────────────────────────────
screenshot() {
    grim /tmp/screenshot.png && satty --filename /tmp/screenshot.png --fullscreen
}

# ──────────────────────────────────────
lock_screen() {
    hyprlock
}

# ──────────────────────────────────────
increase_volume() {
  pactl list short sinks | \
  awk '$NF == "RUNNING" {print $1}' | \
  while read -r sink; do
    current_vol=$(pactl get-sink-volume "$sink" | awk '{print $5}' | sed 's/%//')
    if [ "$current_vol" -lt 100 ]; then
      pactl set-sink-volume "$sink" +5%
    fi
  done
}

# ──────────────────────────────────────
decrease_volume() {
  pactl list short sinks | \
  awk '$NF == "RUNNING" {print $1}' | \
  xargs -I{} pactl set-sink-volume {} -5%
}

# ──────────────────────────────────────
start_agent() {
    echo "Initializing new SSH agent..."
    # spawn ssh-agent
    /usr/bin/ssh-agent | sed 's/^echo/#echo/' > ${SSH_ENV}
    echo succeeded
    chmod 600 ${SSH_ENV}
    . ${SSH_ENV} > /dev/null
    /usr/bin/ssh-add
}

# ──────────────────────────────────────
update_flatpak_packages() {
    local updates
    updates=$(yes n | flatpak update 2>&1 | grep -E '^\s*[0-9]+\.' | wc -l)
    echo "$updates"
    if [ "$updates" -eq 0 ]; then
        pkill -SIGRTMIN+9 waybar
        return 0
    fi

    if flatpak update --noninteractive; then
        notify-send "Update" "Apps updated successfully" -t 1000
    else
        notify-send "Update" "Flathub update failed" -t 1000
    fi

    pkill -SIGRTMIN+9 waybar
}

# ──────────────────────────────────────
check_flatpak_updates() {
    local updates count
    updates=$(flatpak remote-ls --updates --columns=application)
    count=$(echo "$updates" | grep -v '^$' | wc -l)
    if [ "$count" -gt 0 ]; then
        notify-send "Flatpak Updates Available" "$(echo "$updates" | head -n 10)"
        update_flatpak_packages
    fi
    echo "$count"
}

# ──────────────────────────────────────
update_aur_packages() {
    notify-send "Update" "Checking for updates in AUR" -t 1000
    paru -Sy
    pacman -Sy

    pkill -SIGRTMIN+8 waybar

    local updates
    updates=$(paru -Qu 2>/dev/null | wc -l)

    echo "$updates"

    if [ "$updates" -eq 0 ]; then
        notify-send "Update" "No updates available" -t 1000
        pkill -SIGRTMIN+8 waybar
        return 0
    fi

    local PASSWORD
    PASSWORD=$(zenity --password --title="Authentication Required for update") || {
        notify-send "Update" "Cancelled by user" -t 1000
        pkill -SIGRTMIN+8 waybar
        return 1
    }

    # Validate password
    echo "$PASSWORD" | sudo -S true 2>/dev/null || {
        notify-send "Update" "Incorrect password" -t 1000
        pkill -SIGRTMIN+8 waybar
        return 1
    }

    # Run update inside wezterm
    bash -c "
        echo \"$PASSWORD\" | sudo -S pacman -Sy && paru -Sy && paru -Syu --noconfirm 
        if [ \$? -eq 0 ]; then
            notify-send 'Update' 'System packages updated'
            pkill -SIGRTMIN+8 waybar
        else
            notify-send 'Update' 'paru failed'
            pkill -SIGRTMIN+8 waybar
        fi
    "

    pkill -SIGRTMIN+8 waybar
}

# ──────────────────────────────────────
function unlock_ssh {
    SSH_ENV=$HOME/.ssh/environment
    if [ -f "${SSH_ENV}" ]; then
         . ${SSH_ENV} > /dev/null
         ps -ef | grep ${SSH_AGENT_PID} | grep ssh-agent$ > /dev/null || {
            start_agent;
        }
    else
        start_agent;
    fi
}

# ──────────────────────────────────────
#!/bin/bash
function get_unsplash_wallpaper_mac {
    # --- Config ---
    QUERY_LIST="rocks+lake+desert+dunes+mountain"
    COLORS=("black" "black_and_white" "blue")
    WIDTH=1920
    HEIGHT=1080
    WALLPAPER_DIR="$HOME/Pictures/wallpapers"
    WALLPAPER_FILE="$WALLPAPER_DIR/wallpaper.jpg"
    API_KEY_SERVICE="wallpaperapp"

    mkdir -p "$WALLPAPER_DIR"

    # --- Retrieve API key from Keychain ---
    ACCESS_KEY=$(security find-generic-password -s "$API_KEY_SERVICE" -w 2>/dev/null)
    if [[ -z "$ACCESS_KEY" ]]; then
        osascript -e "display alert \"Unsplash API key not found\" message \"Save your Unsplash API key in Keychain with name '$API_KEY_SERVICE'\""
        echo "Save your API key in Keychain: security add-generic-password -a $USER -s $API_KEY_SERVICE -w <your_key>"
        return 1
    fi

    # --- Split QUERY_LIST using macOS-compatible method ---
    OLD_IFS="$IFS"
    IFS='+'
    set -- $QUERY_LIST  # $1, $2, ... contain the queries
    IFS="$OLD_IFS"

    # --- Pick random query ---
    COUNT=$#
    INDEX=$(( RANDOM % COUNT + 1 ))
    QUERY=$(eval echo \$$INDEX)

    # --- Pick random color ---
    COLOR_INDEX=$(( RANDOM % ${#COLORS[@]} ))
    COLOR="${COLORS[$COLOR_INDEX]}"

    # --- Notify ---
    osascript -e "display notification \"Changing wallpaper to '$QUERY' with color '$COLOR'\" with title \"Unsplash Wallpaper\""

    # --- Fetch image URL from Unsplash ---
    API_URL="https://api.unsplash.com/photos/random?query=$QUERY&orientation=landscape&color=$COLOR&client_id=$ACCESS_KEY&w=$WIDTH&h=$HEIGHT"
    IMAGE_URL=$(curl -s "$API_URL" | /usr/bin/env jq -r '.urls.full')

    if [[ -z "$IMAGE_URL" ]] || [[ "$IMAGE_URL" == "null" ]]; then
        echo "Failed to fetch image URL from Unsplash API."
        return 1
    fi

    # --- Download image ---
    curl -s -L -o "$WALLPAPER_FILE" "$IMAGE_URL"

    # --- Set wallpaper on all desktops ---
    osascript <<EOT
tell application "System Events"
    repeat with d in desktops
        set picture of d to "$WALLPAPER_FILE"
    end repeat
end tell
EOT

    echo "Wallpaper set: $QUERY ($COLOR)"
}


# ──────────────────────────────────────
function get_unsplash_wallpaper {
    # Base keywords
    BASE_KEYWORDS=("rocks" "lake" "desert" "dunes" "mountain" "abstract+dark" "abstract+blue+dark" "wallpaper")

    # Randomly choose 1-2 keywords from the base keywords
    NUM_KEYWORDS=$((1 + RANDOM % 1))
    QUERY=$(printf "%s+" $(shuf -n $NUM_KEYWORDS -e "${BASE_KEYWORDS[@]}"))
    QUERY="${QUERY%+}"  # Remove trailing '+'

    notify-send "🌄 Changing wallpaper... $QUERY"

    WIDTH=1920
    HEIGHT=1200
    FILENAME="$HOME/.wallpaper.jpg"
    ACCESS_KEY="$(secret-tool lookup service wallpaperapp)"

    if [[ -z "$ACCESS_KEY" ]]; then
        zenity --warning \
            --title="Token não encontrado" \
            --text="⚠️  O token do Unsplash não foi encontrado.\n\nPor favor, salve-o usando:\n\nsecret-tool store --label=\"Wallpaper App\" service wallpaperapp" \
            --ok-label="OK"
        exit 1
    fi

    # Fetch image URL from Unsplash API
    API_URL="https://api.unsplash.com/photos/random?query=$QUERY&orientation=landscape&client_id=$ACCESS_KEY&w=$WIDTH&h=$HEIGHT"
    IMAGE_URL=$(curl -s "$API_URL" | jq -r '.urls.full')

    if [[ -z "$IMAGE_URL" ]] || [[ "$IMAGE_URL" = "null" ]]; then
        echo "Failed to fetch image URL from Unsplash API."
        exit 1
    fi

    # Download image and set as wallpaper
    wget -q -O "$FILENAME" "$IMAGE_URL"

    # Restart swaybg with new wallpaper
    pkill swaybg
    swaybg -i "$FILENAME" --mode fill &
}

# ──────────────────────────────────────
function gtk_theme {
    echo "Setting GTK theme to adwaita"
    gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3'
    gsettings set org.gnome.desktop.interface icon-theme 'Tela-circle'
}

# ──────────────────────────────────────
translate_selection(){
    selected_text=$(wl-paste --primary | tr -d '\n')
    echo "Selected text: $selected_text" >> /tmp/translate.log
    translation=$(trans -b -t pt <<< "$selected_text")
    echo "Translation: $translation" >> /tmp/translate.log
    zenity --info --title="Output" --text="<span size=\"x-large\">$translation</span>"
}

# ──────────────────────────────────────
fetch_random_wallpaper() {
    local api_url="https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=8&mkt=pt-BR"
    local base_url="https://www.bing.com"
    local output="$HOME/.config/.wallpaper.jpg"
    local output_png="$HOME/.config/.wallpaper.png"
    urls=$(curl -s "$api_url" | jq -r ".images[].url")
    random_url=$(echo "$urls" | shuf -n 1)
    curl -L -o "$output" "${base_url}${random_url}"
    magick convert "$output" "$output_png"
    # Link the new wallpaper to rofi images
    ln -s -f "$output_png" ~/.config/rofi/images/b.png
    ln -s -f "$output_png" ~/.config/rofi/images/a.png
    ln -s -f "$output_png" ~/.config/rofi/images/c.png

    killall swaybg
    swaybg -i "$output_png" 
}

# ──────────────────────────────────────
change_theme(){
	color_scheme=$(gsettings get org.gnome.desktop.interface color-scheme | awk '{print $1}' | tr -d "'")
	# Check the value and set the GTK theme accordingly
	if [ "$color_scheme" = "prefer-dark" ]; then
		gsettings set org.gnome.desktop.interface color-scheme 'default'
        ACTIVE="light"
        printf '{"text": "%s", "tooltip": "%s", "alt": "%s", "class": "light"}\n' "$ACTIVE" "$ACTIVE" "$ACTIVE"
        for file in /run/user/1000/*; do
            if [[ "$file" == *nvim* ]]; then
                nvim --server "$file" --remote-send "<Cmd>SetMyTheme \"light\"<CR>" >/dev/null 2>&1 &
            fi
        done
	else
		gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
        ACTIVE="dark"
        printf '{"text": "%s", "tooltip": "%s", "alt": "%s", "class": "dark"}\n' "$ACTIVE" "$ACTIVE" "$ACTIVE"
        for file in /run/user/1000/*; do
            if [[ "$file" == *nvim* ]]; then
                nvim --server "$file" --remote-send "<Cmd>SetMyTheme \"dark\" <CR>" >/dev/null 2>&1 &
            fi
        done
	fi
}

# ──────────────────────────────────────
get_theme(){
    color_scheme=$(gsettings get org.gnome.desktop.interface color-scheme | tr -d "'")

    case "$color_scheme" in
        prefer-dark)
            ACTIVE="dark"
            CLASS="dark"
            ;;
        prefer-light)
            ACTIVE="light"
            CLASS="light"
            ;;
        default|*)
            # GNOME usa Adwaita Light como padrão
            ACTIVE="light"
            CLASS="light"
            ;;
    esac

    printf '{"text": "%s", "tooltip": "%s", "alt": "%s", "class": "%s"}\n' \
        "$ACTIVE" "$ACTIVE" "$ACTIVE" "$CLASS"
}

# ──────────────────────────────────────
dispatch() {
    local cmd="$1"
    shift

    case "$cmd" in
        clipboard_rofi)        clipboard_rofi "$@" ;;
        launch_rofi)           launch_rofi "$@" ;;
        launch_powermenu)      launch_powermenu "$@" ;;
        startup_services)      startup_services "$@" ;;
        screenshot)            screenshot "$@" ;;
        lock_screen)           lock_screen "$@" ;;
        decrease_volume)       decrease_volume "$@" ;;
        increase_volume)       increase_volume "$@" ;;
        translate_selection)   translate_selection "$@" ;;
        fetch_bing_wallpaper)  fetch_bing_wallpaper "$@" ;;
        fetch_random_wallpaper) fetch_random_wallpaper "$@" ;;
        change_theme)          change_theme "$@" ;;
        unsplash)              get_unsplash_wallpaper "$@" ;;  # macOS function
        update_aur_packages)   update_aur_packages "$@" ;;
        check_flatpak_updates) check_flatpak_updates "$@" ;;
        update_flatpak_packages) update_flatpak_packages "$@" ;;
        get_theme)             get_theme "$@" ;;
        *) 
            echo "Invalid command: $cmd" >&2
            echo "Available commands: clipboard_rofi launch_rofi launch_powermenu startup_services screenshot lock_screen decrease_volume increase_volume translate_selection fetch_bing_wallpaper fetch_random_wallpaper change_theme unsplash update_aur_packages check_flatpak_updates update_flatpak_packages get_theme" >&2
            osascript -e "display notification \"Invalid command: $cmd\" with title \"Dispatch Error\""
            return 1
            ;;
    esac
}

# Call dispatch only if argument is provided
[[ -n "$1" ]] && dispatch "$@"
