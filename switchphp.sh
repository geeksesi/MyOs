#/bin/bash
read -p "Enter your version like 81, 73 : " name
rm -rf /bin/php
ln -s /bin/php$name /bin/php
