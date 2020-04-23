# Hello

# Run cvt 1440 900 (or another resolution if your xrandr can't detect suite resolution for your monitor)
## we need this part : 
### "1440x900_60.00"  106.50  1440 1528 1672 1904  900 903 909 934 -hsync +vsync

xrandr --newmode "1440x900_60.00"  106.50  1440 1528 1672 1904  900 903 909 934 -hsync +vsync
xrandr --addmode VGA-1-1 1440x900_60.00
xrandr --output VGA-1-1 --mode 1440x900_60.00
xrandr --output VGA-1-1 --left-of eDP-1-1 
# i'm using I3 then i want to refresh feh
feh --randomize --bg-scale $HOME/Pictures/Wallpapers/*
