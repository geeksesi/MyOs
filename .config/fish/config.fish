if status is-interactive
    # Commands to run in interactive sessions can go here
end


fish_add_path /home/geeksesi/.local/bin

alias sail './vendor/bin/sail'


alias lbash "docker run --rm \
    -v $PWD:/opt \
    -w /opt \
    laravelsail/php82-composer:latest \
    bash -c "
