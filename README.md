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
