echo 'ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="152d", ATTR{idProduct}=="0576", RUN+="/path/to/your_script.sh"' | sudo tee -a /etc/udev/rules.d/99-my-usb-device.rules

