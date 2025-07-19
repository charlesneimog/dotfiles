
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

    # Panel
    waybar &

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
    swaylock --screenshots \
             --clock \
             --indicator \
             --indicator-radius 100 \
             --indicator-thickness 7 \
             --effect-blur 7x5 \
             --fade-in 0.3 \
             --ring-color 2e3440 \
             --key-hl-color 88c0d0 \
             --line-color 00000000 \
             --inside-color 3b4252 \
             --separator-color 00000000 \
             --text-color d8dee9 \
             --grace 2
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
    notify-send "Update" "Checking for updates for Flatpak" -t 1000

    # Count updates without installing
    updates=$(yes n | flatpak update 2>&1 | grep -E '^\s*[0-9]+\.' | wc -l)
    echo "$updates"

    if [ "$updates" -eq 0 ]; then
        notify-send "Update" "No updates available" -t 1000
        pkill -SIGRTMIN+9 waybar
        return 0
    fi

    # Run the actual update non-interactively
    if flatpak update --noninteractive; then
        notify-send "Update" "Apps updated" -t 1000
    else
        notify-send "Update" "Flathub update failed" -t 1000
    fi

    pkill -SIGRTMIN+9 waybar
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
function get_unsplash_wallpaper {
    # QUERY_LIST="nature+sunset+space+galaxy+nebula+tree+sky+forest+stars+mountain+abstract+minimal+landscape+fog+ocean+cityscape+desert+night+storm+ice+aurora+volcano+geometry+architecture+macro+satellite+moon+planet+fractal+technology+future+cyberpunk"
    QUERY_LIST="abstract+minimal+geometry+fractal+surreal+chaos+order+symmetry+asymmetry+structure+pattern+form+void+contrast+monochrome+gradient+lines+shapes+texture+flow+motion+energy+signal+data+grid+network+vortex+topography+depth+illusion+perspective+isometric+metaphysical+future+cyberpunk+dream"


    if [[ -z "$QUERY_LIST" ]]; then
        echo "❌ QUERY_LIST is empty."
        exit 1
    fi

    IFS='+' read -ra WORDS <<< "$QUERY_LIST"
    if (( ${#WORDS[@]} == 0 )); then
        echo "❌ No words found in QUERY_LIST."
        exit 1
    fi
    QUERY="${WORDS[RANDOM % ${#WORDS[@]}]}"

    notify-send "🌄 Changing wallpaper... $QUERY"

    WIDTH=1920
    HEIGHT=1080
    FILENAME="$HOME/.config/sway/wallpapers/wallpaper.jpg"
    ACCESS_KEY="$(secret-tool lookup service wallpaperapp)"
    if [[ -z "$ACCESS_KEY" ]]; then
      zenity --warning \
        --title="Token não encontrado" \
        --text="⚠️  O token do Unsplash não foi encontrado.\n\nPor favor, salve-o usando:\n\nsecret-tool store --label=\"Wallpaper App\" service wallpaperapp" \
        --ok-label="OK"
    fi

    # Fetch image URL from Unsplash API
    API_URL="https://api.unsplash.com/photos/random?query=$QUERY&orientation=landscape&client_id=$ACCESS_KEY&w=$WIDTH&h=$HEIGHT"
    IMAGE_URL=$(curl -s "$API_URL" | jq -r '.urls.full')

    if [ -z "$IMAGE_URL" ] || [ "$IMAGE_URL" = "null" ]; then
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
	else
		gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
        ACTIVE="dark"
        printf '{"text": "%s", "tooltip": "%s", "alt": "%s", "class": "dark"}\n' "$ACTIVE" "$ACTIVE" "$ACTIVE"
	fi
}

# ──────────────────────────────────────
get_theme(){
	color_scheme=$(gsettings get org.gnome.desktop.interface color-scheme | awk '{print $1}' | tr -d "'")
	if [ "$color_scheme" = "prefer-dark" ]; then
        ACTIVE="dark"
        printf '{"text": "%s", "tooltip": "%s", "alt": "%s", "class": "dark"}\n' "$ACTIVE" "$ACTIVE" "$ACTIVE"
	else
        ACTIVE="light"
        printf '{"text": "%s", "tooltip": "%s", "alt": "%s", "class": "light"}\n' "$ACTIVE" "$ACTIVE" "$ACTIVE"
	fi
}


# ──────────────────────────────────────
dispatch() {
    local cmd="$1"
    shift

    declare -A commands=(
        [clipboard_rofi]=clipboard_rofi
        [launch_rofi]=launch_rofi
        [startup_services]=startup_services
        [screenshot]=screenshot
        [lock_screen]=lock_screen
        [decrease_volume]=decrease_volume
        [increase_volume]=increase_volume
        [translate_selection]=translate_selection
        [fetch_bing_wallpaper]=fetch_bing_wallpaper
        [fetch_random_wallpaper]=fetch_random_wallpaper
        [change_theme]=change_theme
        [unsplash]=get_unsplash_wallpaper
        [update_aur_packages]=update_aur_packages
        [update_flatpak_packages]=update_flatpak_packages
        [get_theme]=get_theme
    )

    if [[ -n "${commands[$cmd]}" ]]; then
        "${commands[$cmd]}" "$@"
    else
        echo "Invalid command: $cmd" >&2
        echo "Available commands: ${!commands[@]}" >&2
        notify-send "Invalid command: $cmd"
        return 1
    fi
}

# Call dispatch only if argument is provided
[[ -n "$1" ]] && dispatch "$@"

