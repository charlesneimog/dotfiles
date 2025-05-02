function start_agent {
    echo "Initializing new SSH agent..."
    # spawn ssh-agent
    /usr/bin/ssh-agent | sed 's/^echo/#echo/' > ${SSH_ENV}
    echo succeeded
    chmod 600 ${SSH_ENV}
    . ${SSH_ENV} > /dev/null
    /usr/bin/ssh-add
}


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


function get_unsplash_wallpaper {
    QUERY="nature+sunset+dark+space+tree"  # Adiciona '-people' para evitar fotos com pessoas

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


function gtk_theme {
    echo "Setting GTK theme to adwaita"
    gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3'
    gsettings set org.gnome.desktop.interface icon-theme 'Tela-circle'
}

translate_selection(){
    selected_text=$(wl-paste --primary | tr -d '\n')
    echo "Selected text: $selected_text" >> /tmp/translate.log
    translation=$(trans -b -t pt <<< "$selected_text")
    echo "Translation: $translation" >> /tmp/translate.log
    zenity --info --title="Output" --text="<span size=\"x-large\">$translation</span>"
}

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


if [ "$1" != "" ]; then
    case $1 in
        translate_selection)
            translate_selection
            ;;
        fetch_bing_wallpaper)
            fetch_bing_wallpaper
            ;;
        fetch_random_wallpaper)
            fetch_random_wallpaper
            ;;
        change_theme)
            change_theme
            ;;
        unsplash)
            get_unsplash_wallpaper;;
        get_theme)
            get_theme
            ;;
        *)
            echo "Invalid argument"
            ;;
    esac
fi
