#!/bin/bash
export=DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
export=DISPLAY=:0

# Verifica se os dispositivos estão conectados
if lsusb | grep -q "152d:0576" && lsusb | grep -q "152d:2329"; then
    notify-send "Ambos os dispositivos JMicron estão conectados!"
else
    notify-send "Aguardando ambos os dispositivos JMicron estarem conectados..."
fi

