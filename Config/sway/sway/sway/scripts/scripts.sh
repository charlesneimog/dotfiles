function unsplash {
    if [[ $# -ne 1 ]]; then
        echo "Usage: unsplash <access_key>"
        return 1
    fi

    local FILENAME=wallpaper.jpg
    local ACCESS_KEY="$1"
    local QUERY="nature"
    local WIDTH=1920
    local HEIGHT=1080
    local API_URL="https://api.unsplash.com/photos/random?query=$QUERY&orientation=landscape&client_id=$ACCESS_KEY&w=$WIDTH&h=$HEIGHT"
    local IMAGE_URL=$(curl -s "$API_URL" | grep -oP '(?<="full":")[^"]*')
    wget -q -O "$FILENAME" "$IMAGE_URL"
}
