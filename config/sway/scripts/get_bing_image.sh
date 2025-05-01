#!/bin/sh

DIR="$HOME/.config/sway/wallpapers/"

# Check if sway/wallpapers directory exists, if not create it.
if [ ! -d "$DIR" ]; then
  mkdir -p $DIR
fi

# Wallpaper path
wlpath="$HOME/.config/sway/wallpapers/wallpaper.jpg"
# Lockscreen wallpaper path
lswlpath="$HOME/.config/sway/wallpapers/lockscreen_wallpaper.jpg"
output="*"
baseurl="https://www.bing.com/"

# Get URL for Bing Image Of The Day for Canada
while [ -z $wlurl ]; do
  wlurl=$(curl $baseurl"HPImageArchive.aspx?format=js&idx=0&n=1&mkt=pt-BR" -s | jq '.images[].url' --raw-output)
done

# Get name for Bing Image of the Day
imageName=$(curl $baseurl"HPImageArchive.aspx?format=js&idx=0&n=1&mkt=pt-BR" -s | jq '.images[].copyright' --raw-output)

# Download and save Bing Image of the Day
curl "$baseurl$wlurl" -s > $wlpath

# Ensure no instances of swaybg and nwg-wrapper are already running
killall swaybg || true
killall nwg-wrapper || true

# Set bing image of the day as wallpaper
swaymsg "output $output bg $wlpath fill"

# Blur existing wallpaper to user later as a lock screen
magick convert $wlpath -filter Gaussian -blur 0x8 -level 10%,90%,0.5 $lswlpath
