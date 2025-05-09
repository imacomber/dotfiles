#!/bin/bash

echo "* installing homebrew *"
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

echo "* installing brew formulae *"
brew install the_silver_searcher git tmux starship fzf lazygit ripgrep neovim lazygit
brew install --cask nikitabobko/tap/aerospace

echo "* cloning dotfiles repo *"
git clone --bare git@github.com:imacomber/dotfiles.git $HOME/.cfg

function config {
  /usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME $@
}

mkdir -p .config-backup
config checkout

if [ $? = 0 ]; then
    echo "Checked out config.";
      else
            echo "Backing up pre-existing dot files.";
                config checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | xargs -I{} mv {} .config-backup/{}
fi;

config checkout
config config status.showUntrackedFiles no

tmux source ~/.tmux.conf
source ~/.zshrc

echo "* installing custom nerd font *"
cp ~/FiraCodeNerdFontMono-Light.ttf ~/Library/Fonts/FiraCodeNerdFontMono-Light.ttf
fc-cache -fv

echo "* making screenshots directory the default for screenshots *"
mkdir ~/screenshots
defaults write com.apple.screencapture location ~/screenshots
