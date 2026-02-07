# If you come from bash you might have to change your $PATH.
export PATH=$HOME:$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH:$HOME/docker-credential-osxkeychain-v0.9.5.darwin-arm64

export ASDF_DATA_DIR=/Users/ianmacomber/.asdf
export PATH="$ASDF_DATA_DIR/shims:$PATH"
export TERM="screen-256color"
export EDITOR='vim'

export AWS_EC2_METADATA_DISABLED=true

source <(fzf --zsh)
# bindkey '^R' history-incremental-search-backward

export SPX_WORKSTATION_PROFILES="backend,datascience,devops,frontend,rcis-workspace"

alias vim='vim'
alias sz='source ~/.zshrc'
alias vz='vim ~/.zshrc'
alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'
alias rt='rspec'
alias dbm='rails db:migrate'
alias tmux="TERM=screen-256color-bce tmux"

alias dcu='docker-compose up && docker-compose logs -f'
alias dcd='docker-compose down'

alias gd='git diff'
alias gp='git fetch origin -p && git rebase origin/$(git rev-parse --abbrev-ref HEAD)'
alias gco='git commit -m'
alias gch='git checkout --'
alias gpu="git push -u origin $(git rev-parse --abbrev-ref HEAD)"
alias gfpu="git push origin $(git rev-parse --abbrev-ref HEAD) --force"
alias gc='git checkout'
alias gb='git branch'
alias gbn='gc main && gp && git checkout -b'
alias gbd='gc main && gb -D'
alias gs='git status'
alias gu='git reset HEAD'
alias gac='git add -u && git commit -m'
alias grm="gc main && gp"
alias gst='git stash'
alias gsp='git stash pop'
alias gsl='git stash list'
alias gss='git stash show'
alias gsd='git stash drop'

eval "$(starship init zsh)"
