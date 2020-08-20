#
# ~/.bashrc
#

export NODE_ENV=development

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

HISTSIZE=20000
HISTFILESIZE=40000
HISTCONTROL=ignoredups:erasedups
HISTIGNORE="history:rm"

PATH=$PATH:~/.local/bin:~/.yarn/bin:~/.cargo/bin

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion