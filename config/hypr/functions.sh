#!/bin/bash

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

decrease_volume() {
  pactl list short sinks | \
  awk '$NF == "RUNNING" {print $1}' | \
  xargs -I{} pactl set-sink-volume {} -5%
}



translate_selection(){
    selected_text=$(wl-paste --primary | tr -d '\n')
    echo "Selected text: $selected_text" >> /tmp/translate.log
    translation=$(trans -b -t pt <<< "$selected_text")
    echo "Translation: $translation" >> /tmp/translate.log
    zenity --info --title="Output" --text="<span size=\"x-large\">$translation</span>"
}


fetch_bing_wallpaper() {
    local api_url="https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=2&mkt=pt-BR"
    local base_url="https://www.bing.com"
    local output="$HOME/.config/hypr/wallpaper.jpg"
    local output_png="$HOME/.config/hypr/wallpaper.png"
    local url_path=$(curl -s "$api_url" | jq -r ".images[0].url")
    curl -L -o "${output}" "${base_url}${url_path}"
    convert "${output}" "${output_png}"
    mkdir -p ~/.config/rofi/images/
    ln -s -f "${output_png}" ~/.config/rofi/images/b.png
    ln -s -f "${output_png}" ~/.config/rofi/images/a.png
    ln -s -f "${output_png}" ~/.config/rofi/images/c.png
}

fetch_random_wallpaper() {
    local api_url="https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=20&mkt=pt-BR"
    local base_url="https://www.bing.com"
    local output="$HOME/.config/hypr/wallpaper.jpg"
    local output_png="$HOME/.config/hypr/wallpaper.png"
    urls=$(curl -s "$api_url" | jq -r ".images[].url")
    random_url=$(echo "$urls" | shuf -n 1)
    curl -L -o "$output" "${base_url}${random_url}"
    convert "$output" "$output_png"
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
        decrease_volume)
            decrease_volume 
            ;;
        increase_volume)
            increase_volume 
            ;;
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


