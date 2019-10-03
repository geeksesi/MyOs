tor=C:\Users\javad\Downloads\Progs\Tor\tor.exe 
ls=dir
apache_log=tail -f C:\xampp\apache\logs\error.log
doskey_backup="doskey /macros >C:\Users\javad\macros.cmd"
ln=mklink
madahi=youtube-dl -f best,140 --embed-thumbnail --add-metadata --xattrs  --no-playlist --mark-watched -c --write-thumbnail -o "C:\Users\javad\Music\My_madahi\%(ext)s\%(title)s.%(ext)s" $*
