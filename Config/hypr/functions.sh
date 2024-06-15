#!/bin/bash

translate_selection(){
    selected_text=$(xsel -o | tr -d '\n')
    translation=$(trans -b -t pt <<< "$selected_text")
    zenity --info --title="Output" --text="<span size=\"x-large\">$translation</span>"
}

fetch_bing_wallpaper() {
    local api_url="https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1&mkt=pt-BR"
    local base_url="https://www.bing.com"
    local output="$HOME/.config/hypr/wallpaper.jpg"
    local output_png="$HOME/.config/hypr/wallpaper.png"
    local url_path=$(curl -s "$api_url" | jq -r ".images[0].url")
    curl -L -o "${output}" "${base_url}${url_path}"
    convert "${output}" "${output_png}"
}

change_theme(){
	color_scheme=$(gsettings get org.gnome.desktop.interface color-scheme | awk '{print $1}' | tr -d "'")
	# Check the value and set the GTK theme accordingly
	if [ "$color_scheme" = "prefer-dark" ]; then
		gsettings set org.gnome.desktop.interface color-scheme 'default'
        ACTIVE="light"
        printf '{"text": "%s", "tooltip": "%s", "alt": "%s"}\n' "$ACTIVE" "$ACTIVE" "$ACTIVE"
	else
		gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
        ACTIVE="dark"
        printf '{"text": "%s", "tooltip": "%s", "alt": "%s"}\n' "$ACTIVE" "$ACTIVE" "$ACTIVE"
	fi
}

get_theme(){
	color_scheme=$(gsettings get org.gnome.desktop.interface color-scheme | awk '{print $1}' | tr -d "'")
	if [ "$color_scheme" = "prefer-dark" ]; then
        ACTIVE="dark"
        printf '{"text": "%s", "tooltip": "%s", "alt": "%s"}\n' "$ACTIVE" "$ACTIVE" "$ACTIVE"
	else
        ACTIVE="light"
        printf '{"text": "%s", "tooltip": "%s", "alt": "%s"}\n' "$ACTIVE" "$ACTIVE" "$ACTIVE"
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


