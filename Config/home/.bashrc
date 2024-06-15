# Latex
export TEXMFHOME=~/.texmf
export PATH="/home/neimog/Documents/Git/dotfiles/Scripts:$PATH"

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
PS1='[\u@\h \W]\$ '

if ! pgrep -u "$USER" ssh-agent > /dev/null; then
    ssh-agent -t 1h > "$XDG_RUNTIME_DIR/ssh-agent.env"
fi
if [[ ! -f "$SSH_AUTH_SOCK" ]]; then
    source "$XDG_RUNTIME_DIR/ssh-agent.env" >/dev/null
fi


bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/neimog/.config/miniconda3.dir/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/neimog/.config/miniconda3.dir/etc/profile.d/conda.sh" ]; then
        . "/home/neimog/.config/miniconda3.dir/etc/profile.d/conda.sh"
    else
        export PATH="/home/neimog/.config/miniconda3.dir/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<


