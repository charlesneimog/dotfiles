#!/bin/bash

choice=$(zenity --list \
  --title="External Monitor Mode" \
  --column="Options" \
  "This Monitor (only)" \
  "External Monitor (only)" \
  "Duplicate" \
  "Extend")

# Customize these with your actual output names
INTERNAL="eDP-1"
EXTERNAL="HDMI-A-1"

case "$choice" in
  "This Monitor (only)")
    swaymsg output "$EXTERNAL" disable
    swaymsg output "$INTERNAL" enable
    ;;
  "External Monitor (only)")
    swaymsg output "$INTERNAL" disable
    swaymsg output "$EXTERNAL" enable
    ;;
  "Duplicate")
    swaymsg output "$EXTERNAL" enable
    swaymsg output "$EXTERNAL" pos 0 0
    swaymsg output "$INTERNAL" enable
    swaymsg output "$INTERNAL" pos 0 0
    ;;
  "Extend")
    swaymsg output "$INTERNAL" enable
    swaymsg output "$INTERNAL" pos 0 0
    swaymsg output "$EXTERNAL" enable
    swaymsg output "$EXTERNAL" pos 1920 0 
    ;;
esac

