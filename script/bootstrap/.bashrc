if [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
fi

function parse_git_branch {
  local branch=$(__git_ps1 "%s")
  [[ $branch ]] && echo "[$branch]"
}

export HISTCONTROL=erasedups
export HISTSIZE=50000
export PS1='\[\033[1;33m\]\w\[\033[0m\]$(parse_git_branch)$ '

shopt -s histappend

alias ll='ls -l'
alias ls='ls -ApG'
