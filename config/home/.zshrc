#╭──────────────────────────────────────╮
#│                Theme                 │
#╰──────────────────────────────────────╯
ZSH_THEME="robbyrussell"
autoload -U promptinit && promptinit
eval "$(oh-my-posh init zsh --config $HOME/.oh-my-posh.toml)"


#╭──────────────────────────────────────╮
#│              Variables               │
#╰──────────────────────────────────────╯
export CMAKE_GENERATOR="Ninja"
export CMAKE_BUILD_PARALLEL_LEVEL=12
export MAKEFLAGS="-j12"
export NINJAFLAGS="-j12"
export PATH="/home/neimog/.local/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export EDITOR=nvim

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

# Shell integrations
source /usr/share/fzf/key-bindings.zsh
source /usr/share/fzf/completion.zsh
eval "$(zoxide init --cmd cd zsh)"

#╭──────────────────────────────────────╮
#│               Aliases                │
#╰──────────────────────────────────────╯
alias ls='ls --color'
alias v='nvim'
alias n='nvim'
alias c='clear'
alias inkscape='org.inkscape.Inkscape'
alias cat='bat --paging=never'

#╭──────────────────────────────────────╮
#│                 Yazi                 │
#╰──────────────────────────────────────╯
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

# pnpm end
PATH=/usr/local/bin:$PATH 
alias wish='/usr/local/bin/wish9.1'
source /home/neimog/.config/miniconda3.dir/etc/profile.d/conda.sh
ibus-daemon -drx
## Completion scripts setup. Remove the following line to uninstall
[[ -f /home/neimog/.dart-cli-completion/zsh-config.zsh ]] && . /home/neimog/.dart-cli-completion/zsh-config.zsh || true
