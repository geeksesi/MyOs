if status is-interactive
    # Commands to run in interactive sessions can go here
end


fish_add_path /home/geeksesi/.local/bin
fish_add_path /home/geeksesi/Downloads/bin

alias sail './vendor/bin/sail'


alias lbash "docker run --rm \
    -v $PWD:/opt \
    -w /opt \
    laravelsail/php82-composer:latest \
    bash -c "

alias w '../../../w.sh'


# opencode
fish_add_path /home/geeksesi/.opencode/bin

# Set Fish as shell prefix for Claude Code (experimental)
# set -gx CLAUDE_CODE_SHELL_PREFIX "fish -c"

# Claude Status Bar Monitor
alias cs='claude-statusbar'
alias cstatus='claude-statusbar'
