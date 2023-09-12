if status is-interactive
    # Commands to run in interactive sessions can go here
end

alias AVPN 'sudo openconnect  --reconnect-timeout 20 --authgroup=cisco -dbu geeksesi sv35.fzserver.com:4443'
alias BVPN 'sudo -b openvpn --config Downloads/firefox/sv103-us-combined.ovpn'

fish_add_path /home/geeksesi/.local/bin

alias sail './vendor/bin/sail'
alias sf './node_modules/.bin/sf'
alias sfdx './node_modules/.bin/sfdx'

alias KVPN 'sudo killall -q openvpn || sudo killall -q openconnect'

alias padmin 'php -S 127.0.0.1:8083 -t /home/geeksesi/public_html/padmin/'


alias lbash "docker run --rm \
    -v $PWD:/opt \
    -w /opt \
    laravelsail/php82-composer:latest \
    bash -c "

#fish_add_path /home/geeksesi/public_html/TON/bin

#set -U https_proxy http://127.0.0.1:9053
#set -U http_proxy http://127.0.0.1:9053
nvm use --silent 