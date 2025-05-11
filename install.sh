#!/usr/bin/env bash

newline() {
  echo "\n"
}

config() {
  /usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME $@
}

install_homebrew() {
  echo "* installing homebrew 🍺 *"
  newline

  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"

  newline
  echo "* homebrew install; bundling formulae and casks 🍻 *"
  newline

  brew bundle
}

install_dotfiles() {
  echo "* cloning dotfiles repo 🐙 *"
  newline

  git clone --bare git@github.com:imacomber/dotfiles.git $HOME/.cfg

  config checkout

  if [ $? = 0 ]; then
    echo "* successfully cloned and checked out repo ✅ *"
    newline
  else
    echo "* backing up existing dotfiles 💾 *"
    newline

    mkdir -p .config-backup
    config checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | xargs -I{} mv {} .config-backup/{}
  fi;

  config checkout
  config config status.showUntrackedFiles no

  echo "* successfull installed dotfiles ✅ *"
}

initialize_tmux() {
  echo "* initializing tmux 🪟 *"
  newline

  tmux source ~/.tmux.conf
  source ~/.zshrc
}

install_nerdfont() {
  echo "* installing custom nerd font 🤓 *"
  newline

  cp ~/FiraCodeNerdFontMono-Light.ttf ~/Library/Fonts/FiraCodeNerdFontMono-Light.ttf
  fc-cache -fv
}

customize_screenshots() {
  echo "* customizing screenshots directory 📷 *"

  mkdir ~/screenshots
  defaults write com.apple.screencapture location ~/screenshots
}

install_homebrew
install_dotfiles
initialize_tmux
install_nerdfont
customize_screenshots
