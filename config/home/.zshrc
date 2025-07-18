ZSH_THEME="robbyrussell"
autoload -U promptinit && promptinit
eval "$(oh-my-posh init zsh --config $HOME/.oh-my-posh.toml)"

#╭──────────────────────────────────────╮
#│                ZINIT                 │
#╰──────────────────────────────────────╯
# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add in zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# Add in snippets
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::archlinux
zinit snippet OMZP::command-not-found

# Load completions
autoload -Uz compinit && compinit
zinit cdreplay -q

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Keybindings
bindkey -e
bindkey '^j' history-search-backward
bindkey '^k' history-search-forward
bindkey '^ ' autosuggest-accept

# History
HISTSIZE=1000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Aliases
alias ls='ls --color'
alias v='nvim'
alias n='nvim'
alias c='clear'
alias cat='bat --paging=never'


# Shell integrations
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"

#╭──────────────────────────────────────╮
#│             Conda Setup              │
#╰──────────────────────────────────────╯
export PATH="$PATH:/home/neimog/.local/bin"

#╭──────────────────────────────────────╮
#│                 Yazi                 │
#╰──────────────────────────────────────╯
export EDITOR=nvim
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

# Dark
export FZF_DEFAULT_OPTS="--color=bg+:#383838,bg:#303030,spinner:#303030,hl:#e78284 --color=fg:#c6d0f5,header:#e78284,info:#ca9ee6,pointer:#ff0000 --color=marker:#babbf1,fg+:#c6d0f5,prompt:#ca9ee6,hl+:#e78284 --color=selected-bg:#51576d --multi"

# This setting also does not set the output color of this matching character
export FZF_DEFAULT_OPTS="--height=20% --info=inline --margin=1 --padding=1 --color=hl+:#000000"


# Added by LM Studio CLI (lms)
export PATH="$PATH:/home/neimog/.lmstudio/bin"

# pnpm
export PNPM_HOME="/home/neimog/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
#
PATH=/usr/local/bin:$PATH 
alias wish='/usr/local/bin/wish9.1'


# . "/home/neimog/.config/miniconda3.dir/etc/profile.d/conda.sh"  # commented out by conda initialize

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/neimog/.config/miniconda3.dir/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
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



export PATH="/home/neimog/.pixi/bin:$PATH"

## [Completion]
## Completion scripts setup. Remove the following line to uninstall
[[ -f /home/neimog/.dart-cli-completion/zsh-config.zsh ]] && . /home/neimog/.dart-cli-completion/zsh-config.zsh || true
## [/Completion]
