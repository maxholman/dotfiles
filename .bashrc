#
# ~/.bashrc
#

# safe default
export NODE_ENV=development

# picom incompatibility - see https://github.com/google/xsecurelock/issues/97
export XSECURELOCK_COMPOSITE_OBSCURER=0

# we use pommel to populate this var at run time
# NPM insists it is populated if you have an npmrc file with an env var
export NPM_TOKEN=its-a-secret-dummy

# =============================================================================
# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias vi='vim'

PS1='[\u@\h \W]\$ '
TERMINAL=rxvt-unicode
EDITOR=/usr/bin/vim

# append to the history file, don't overwrite it
shopt -s histappend

HISTSIZE=20000
HISTFILESIZE=40000
HISTCONTROL=ignoreboth:erasedups
HISTIGNORE="history:rm"

PATH=$PATH:~/.local/bin
PATH=$PATH:~/.yarn/bin
PATH=$PATH:~/.cargo/bin

# Terraform
PATH=$PATH:~/.tfenv/bin
export TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"
#complete -C $(which terraform) terraform

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

#source "$HOME/.cargo/env"
