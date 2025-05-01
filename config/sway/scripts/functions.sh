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

function unsplash {
    sleep 5
    local QUERY="nature"
    local WIDTH=1920
    local HEIGHT=1080
    local FILENAME=~/.config/sway/wallpapers/wallpaper.jpg
    
    # Prompt for Bitwarden password
    local PASSWORD=$(zenity --password --title="Enter Password for BW Session" --timeout=120)
    if [ -z "$PASSWORD" ]; then
        echo "Password entry timed out."
        return 1
    fi

    # Unlock Bitwarden session
    local BW_SESSION=$(bw unlock "$PASSWORD" --raw)
    if [ -z "$BW_SESSION" ]; then
        echo "Failed to unlock Bitwarden session."
        return 1
    fi
    
    # Retrieve Access Key from Bitwarden
    local ACCESS_KEY=$(bw --session "$BW_SESSION" get item 19777761-d8c9-4429-bcc1-b11800079334 | jq -r '.login.password')
    if [ -z "$ACCESS_KEY" ]; then
        echo "Failed to retrieve Access Key from Bitwarden."
        return 1
    fi
    
    # Fetch image URL from Unsplash API
    local API_URL="https://api.unsplash.com/photos/random?query=$QUERY&orientation=landscape&client_id=$ACCESS_KEY&w=$WIDTH&h=$HEIGHT"
    local IMAGE_URL=$(curl -s "$API_URL" | jq -r '.urls.full')
    if [ -z "$IMAGE_URL" ]; then
        echo "Failed to fetch image URL from Unsplash API."
        return 1
    fi
    
    # Download image and set as wallpaper
    wget -q -O "$FILENAME" "$IMAGE_URL"
    killall -q swaybg && swaybg -i "$FILENAME" --mode fill
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
        get_theme)
            get_theme
            ;;
        *)
            echo "Invalid argument"
            ;;
    esac
fi
