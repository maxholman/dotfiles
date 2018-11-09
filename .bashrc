#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias vi='vim'
alias docker='sudo docker'
alias docker-compose='sudo docker-compose'

PS1='[\u@\h \W]\$ '
TERMINAL=rxvt-unicode
NODE_ENV=development
EDITOR=/usr/bin/vim

HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoredups:erasedups
HISTIGNORE="ls:ps:history:cd"

# AWS assume role tool
source ~/.dotfiles/bin/assume-role.sh

PATH=$PATH:~/.local/bin

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
