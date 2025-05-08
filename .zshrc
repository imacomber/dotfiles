# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:/usr/local/bin:$PATH

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

export PATH=/Applications/Postgres.app/Contents/Versions/9.4/bin:$PATH
export PGDATABASE=postgres
export TERM="screen-256color"
export EDITOR='vim'
export EZ_RAILS_DEV_DATA=partial
export DELIVERY_DEV_DATA=partial
export DELIVERY_MANAGEMENT_DEV_DATA=partial

# db book env
export DATABASE_URL='postgres://owner:@localhost:5432/rideshare_development'
export RIDESHARE_DB_PASSWORD="HSnDDgFtyW9fyFI"
export DB_URL='postgres://postgres:@localhost:5432/postgres'
alias rideshare_reset='cd rideshare && bin/rails db:reset && sh db/setup.sh && bin/rails db:migrate'

source <(fzf --zsh)
# bindkey '^R' history-incremental-search-backward

alias vim='vim'
alias sz='source ~/.zshrc'
alias vz='vim ~/.zshrc'
alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'
alias rt='rspec'
alias dbm='rails db:migrate'
alias tmux="TERM=screen-256color-bce tmux"
alias run='/Users/ianmacomber/source/eztilt/run'
alias eztilt='/Users/ianmacomber/source/eztilt/eztilt'
alias tail='clear'

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

# dev1 pods
alias dev-ezrails-pod='kubectl --context staging get pod -l application=ezrails,role=console  -n dev1 -o jsonpath="{.items[0].metadata.name}"'
alias dev-docs-pod='kubectl --context staging get pod -l application=docs,role=console  -n dev1 -o jsonpath="{.items[0].metadata.name}"'
alias dev-delivery-management-pod='kubectl --context staging get pod -l application=delivery-management-rails,role=console -n dev1 -o jsonpath="{.items[0].metadata.name}"'
alias dev-delivery-pod='kubectl --context staging get pod -l application=delivery,role=console  -n dev1 -o jsonpath="{.items[0].metadata.name}"'
alias dev-external-events-pod='kubectl --context staging get pod -l application=external-events,role=console  -n dev1 -o jsonpath="{.items[0].metadata.name}"'
alias dev-identity-pod='kubectl --context staging get pod -l application=identity,role=console  -n dev1 -o jsonpath="{.items[0].metadata.name}"'
alias dev-auth-pod='kubectl --context staging get pod -l application=authentication,role=console  -n dev1 -o jsonpath="{.items[0].metadata.name}"'
# rainforest pods
alias rainforest-ezrails-pod='kubectl --context staging get pod -l application=ezrails,role=console -n rainforestqa -o jsonpath="{.items[0].metadata.name}"'
# staging pods
alias pos-pod='kubectl --context staging get pod -l application=pos,role=console -o jsonpath="{.items[0].metadata.name}"'
alias ezrails-pod='kubectl --context staging get pod -l application=ezrails,role=console -o jsonpath="{.items[0].metadata.name}"'
alias omnichannel-pod='kubectl --context staging get pod -l application=omnichannel,role=console -o jsonpath="{.items[0].metadata.name}"'
alias delivery-pod='kubectl --context staging get pod -l application=delivery,role=console -o jsonpath="{.items[0].metadata.name}"'
alias docs-pod='kubectl --context staging get pod -l application=docs,role=console -o jsonpath="{.items[0].metadata.name}"'
alias delivery-management-pod='kubectl --context staging get pod -l application=delivery-management-rails,role=console -o jsonpath="{.items[0].metadata.name}"'
# production pods
alias prod-pos-pod='kubectl --context production get pod -l application=pos,role=console -o jsonpath="{.items[0].metadata.name}"'
alias prod-ezrails-pod='kubectl --context production get pod -l application=ezrails,role=console -o jsonpath="{.items[0].metadata.name}"'
alias prod-omnichannel-pod='kubectl --context production get pod -l application=omnichannel,role=console -o jsonpath="{.items[0].metadata.name}"'
alias prod-delivery-pod='kubectl --context production get pod -l application=delivery,role=console -o jsonpath="{.items[0].metadata.name}"'
alias prod-docs-pod='kubectl --context production get pod -l application=docs,role=console -o jsonpath="{.items[0].metadata.name}"'
alias prod-delivery-management-pod='kubectl --context production get pod -l application=delivery-management-rails,role=console -o jsonpath="{.items[0].metadata.name}"'
alias prod-identity-pod='kubectl --context production get pod -l application=identity,role=console -o jsonpath="{.items[0].metadata.name}"'
alias prod-auth-pod='kubectl --context production get pod -l application=authentication,role=console -o jsonpath="{.items[0].metadata.name}"'
# dev1 kube commands
alias kdmb='kubectl exec --context staging -it $(dev-delivery-management-pod) -n dev1 -- /bin/bash'
alias kdmc='kubectl exec --context staging -it $(dev-delivery-management-pod) -n dev1 -- rails c'
alias kdeb='kubectl exec --context staging -it $(dev-ezrails-pod) -n dev1 -- /bin/bash'
alias kdec='kubectl exec --context staging -it $(dev-ezrails-pod) -n dev1 -- rails c'
alias kddb='kubectl exec --context staging -it $(dev-delivery-pod) -n dev1 -- /bin/bash'
alias kddc='kubectl exec --context staging -it $(dev-delivery-pod) -n dev1 -- rails c'
alias kdxb='kubectl exec --context staging -it $(dev-external-events-pod) -n dev1 -- /bin/bash'
alias kdxc='kubectl exec --context staging -it $(dev-external-events-pod) -n dev1 -- rails c'
alias kdcb='kubectl exec --context staging -it $(dev-docs-pod) -n dev1 -- /bin/bash'
alias kdcc='kubectl exec --context staging -it $(dev-docs-pod) -n dev1 -- rails c'
alias kdib='kubectl exec --context staging -it $(dev-identity-pod) -n dev1 -- /bin/bash'
alias kdic='kubectl exec --context staging -it $(dev-identity-pod) -n dev1 -- rails c'
alias kdab='kubectl exec --context staging -it $(dev-auth-pod) -n dev1 -- /bin/bash'
alias kdac='kubectl exec --context staging -it $(dev-auth-pod) -n dev1 -- rails c'
# rainforest kube commands
alias kreb='kubectl exec --context staging -it $(rainforest-ezrails-pod) -n rainforestqa -- /bin/bash'
alias krec='kubectl exec --context staging -it $(rainforest-ezrails-pod) -n rainforestqa -- rails c'
# staging kube commands
alias kspc='kubectl exec --context staging -it $(pos-pod) -- rails c'
alias kspb='kubectl exec --context staging -it $(pos-pod) -- /bin/bash'
alias kseb='kubectl exec --context staging -it $(ezrails-pod) -- /bin/bash'
alias ksec='kubectl exec --context staging -it $(ezrails-pod) -- rails c'
alias ksob='kubectl exec --context staging -it $(omnichannel-pod) -- /bin/bash'
alias ksoc='kubectl exec --context staging -it $(omnichannel-pod) -- rails c'
alias ksdb='kubectl exec --context staging -it $(delivery-pod) -- /bin/bash'
alias ksdc='kubectl exec --context staging -it $(delivery-pod) -- rails c'
alias kscb='kubectl exec --context staging -it $(docs-pod) -- /bin/bash'
alias kscc='kubectl exec --context staging -it $(docs-pod) -- rails c'
alias ksmb='kubectl exec --context staging -it $(delivery-management-pod) -- /bin/bash'
alias ksmc='kubectl exec --context staging -it $(delivery-management-pod) -- rails c'
# production kube commands
alias kpac='kubectl exec --context production -it $(prod-auth-pod) -- rails c'
alias kppb='kubectl exec --context production -it $(prod-pos-pod) -- /bin/bash'
alias kppc='kubectl exec --context production -it $(prod-pos-pod) -- rails c'
alias kpeb='kubectl exec --context production -it $(prod-ezrails-pod) -- /bin/bash'
alias kpec='kubectl exec --context production -it $(prod-ezrails-pod) -- rails c'
alias kpic='kubectl exec --context production -it $(prod-identity-pod) -- rails c'
alias kpob='kubectl exec --context production -it $(prod-omnichannel-pod) -- /bin/bash'
alias kpoc='kubectl exec --context production -it $(prod-omnichannel-pod) -- rails c'
alias kpdb='kubectl exec --context production -it $(prod-delivery-pod) -- /bin/bash'
alias kpdc='kubectl exec --context production -it $(prod-delivery-pod) -- rails c'
alias kpcb='kubectl exec --context production -it $(prod-docs-pod) -- /bin/bash'
alias kpcc='kubectl exec --context production -it $(prod-docs-pod) -- rails c'
alias kpmb='kubectl exec --context production -it $(prod-delivery-management-pod) -- /bin/bash'
alias kpmc='kubectl exec --context production -it $(prod-delivery-management-pod) -- rails c'
alias ezk='docker run --rm -v "$HOME/.aws:/root/.aws:ro" -v "$HOME/.kube:/root/.kube" -v "$(pwd)/service.yml:/usr/src/gem/service.yml:ro" -it ezcater-production.jfrog.io/ezk-gem ezk'

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"

eval "$(starship init zsh)"

. "$HOME/.asdf/asdf.sh"
export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"
