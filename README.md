 INSTALLATION
===============

1. Clone repo
2. Install:
   ./install.sh

3. Install with grub and sddm theme:
   ./install.sh --with-system-themes

   For only sddm:

   ./install.sh --with-sddm

   Only grub:

   ./install.sh --with-grub

4. Reastart your sddm:

   sudo systemctl restart sddm

5. Reboot for see grub theme:

   reboot

6. Install TLP power profile (NVIDIA dGPU sleeps on battery):

   ./install.sh --with-tlp

   Or apply only the TLP part:

   sudo bash tlp/apply.sh

   Power Safe mode is in the Waybar right side. Left click toggles it,
   right click shows the status. Settings live in
   ~/.config/waybar/power-safe.conf (TLP is verified automatically).
   Waybar has no terminal, so the first root action opens a
   zenity/kdialog password prompt.

   When enabled, Power Safe limits the CPU to 1.5 GHz and switches all
   active monitors to 60 Hz. When disabled, it restores the normal CPU
   limit and the highest refresh rate available for the current
   resolution. `power-safe.sh ensure` re-applies 60 Hz after a Hyprland
   reload, and `power-safe.sh reset` force-restores CPU/GPU/display
   defaults if a toggle is interrupted.

   The on/off state is stored in $XDG_RUNTIME_DIR, so logout or reboot
   clears it: Power Safe cannot stay enabled forever across reboots.
   A lock prevents double-click races while a toggle is running.

   Note: the NVIDIA GPU can only enter RTD3 suspend when no running
   program keeps it open (for example a browser using it, or the SDDM
   Xorg greeter). TLP sets runtime PM to auto; the GPU then powers down
   when it becomes idle.
