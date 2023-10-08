# picom incompatibility - see https://github.com/google/xsecurelock/issues/97
export XSECURELOCK_COMPOSITE_OBSCURER=0

# =============================================================================
# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias vi='vim'

PS1='[\u@\h \W]\$ '
TERMINAL=alacritty
EDITOR=/usr/bin/vim

# append to the history file, don't overwrite it
shopt -s histappend

HISTSIZE=20000
HISTFILESIZE=40000
HISTCONTROL=ignoreboth:erasedups
HISTIGNORE="history:rm"

PATH=$PATH:~/.local/bin
PATH=$PATH:~/.yarn/bin

# android sdk
export ANDROID_HOME=~/Android/Sdk
PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin/

# Terraform
#PATH=$PATH:~/.tfenv/bin
#export TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"
#complete -C $(which terraform) terraform

#source "$HOME/.cargo/env"
PATH=$PATH:~/.cargo/bin

# Flutter
PATH=$PATH:~/Projects/personal/flutter/bin

#
# Node + NVM
#
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# we use pommel to populate this var at run time
# NPM insists it is populated if you have an npmrc file with an env var
export NPM_TOKEN=its-a-secret-dummy

# safe default
export NODE_ENV=development

###### Make sure the current user/path is shown in the terminal title
# Make sure the current user/path is shown in the terminal title
case ${TERM} in
  xterm*|rxvt*|Eterm|alacritty*|aterm|kterm|gnome*)
     PROMPT_COMMAND=${PROMPT_COMMAND:+$PROMPT_COMMAND; }'printf "\033]0;%s@%s:%s\007" "${USER}" "${HOSTNAME%%.*}" "${PWD/#$HOME/\~}"'
    ;;
  screen*)
    PROMPT_COMMAND=${PROMPT_COMMAND:+$PROMPT_COMMAND; }'printf "\033_%s@%s:%s\033\\" "${USER}" "${HOSTNAME%%.*}" "${PWD/#$HOME/\~}"'
    ;;
esac

KUBE_EDITOR="vim"