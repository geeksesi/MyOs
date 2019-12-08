sudo apt update && sudo apt upgrade -y && \
sudo apt install -y \
	fish \
	flameshot \
	i3 i3-wm i3lock i3-block i3status \
	mpv \
	xfce4-volumed xfce4-power-manager \
	parole \
	tor obfs4proxy \
	vim && \
cd Download && mkdir T_D && mkdir firefox && cd T_D && \
wget https://atom.io/download/deb -o atom.deb && \
sudo dpkg -i atom.deb -y && \
sudo apt install -f -y && \
