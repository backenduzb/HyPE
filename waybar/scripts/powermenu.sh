#!/bin/bash

choice=$(printf "󰐥 Shutdown\n Reboot\n Lock\n Logout" | rofi -dmenu -i -theme ~/.config/rofi/powermenu.rasi -p "Power")

case "$choice" in
  *Shutdown) systemctl poweroff ;;
  *Reboot) systemctl reboot ;;
  *Lock) hyprlock ;;
  *Logout) hyprctl dispatch exit ;;
esac
