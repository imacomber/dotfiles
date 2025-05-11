#!/usr/bin/env bash
set -euo pipefail

LOGFILE="$HOME/setup.log"
exec > >(tee -a "$LOGFILE") 2>&1

newline() {
  echo
}

config() {
  /usr/bin/git --git-dir="$HOME/.cfg/" --work-tree="$HOME" "$@"
}

install_homebrew() {
  echo "* installing Homebrew 🍺 *"
  newline

  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  else
    echo "❌ Homebrew not found after install. Exiting."
    exit 1
  fi

  newline
  echo "* bundling formulae and casks 🍻 *"
  newline

  brew bundle || echo "⚠️ brew bundle failed (might be missing Brewfile)"
}

install_dotfiles() {
  echo "* cloning dotfiles repo 🐙 *"
  newline

  if [[ -d "$HOME/.cfg" ]]; then
    echo "⚠️ Dotfiles repo already exists. Skipping clone."
  else
    git clone --bare git@github.com:imacomber/dotfiles.git "$HOME/.cfg"
  fi

  if config checkout; then
    echo "* successfully cloned and checked out repo ✅ *"
    newline
  else
    echo "* backing up existing dotfiles 💾 *"
    newline

    mkdir -p "$HOME/.config-backup"
    config checkout 2>&1 | grep -E "\s+\." | awk '{print $1}' | while read -r file; do
      mkdir -p "$(dirname "$HOME/.config-backup/$file")"
      mv "$HOME/$file" "$HOME/.config-backup/$file"
    done
  fi

  config checkout
  config config status.showUntrackedFiles no

  echo "* successfully installed dotfiles ✅ *"
}

initialize_tmux() {
  echo "* initializing tmux 🪟 *"
  newline

  if command -v tmux >/dev/null; then
    tmux source "$HOME/.tmux.conf"
  else
    echo "⚠️ tmux not found, skipping."
  fi
}

install_nerdfont() {
  echo "* installing custom nerd font 🤓 *"
  newline

  FONT_SRC="$HOME/FiraCodeNerdFontMono-Light.ttf"
  FONT_DEST="$HOME/Library/Fonts/FiraCodeNerdFontMono-Light.ttf"

  if [[ -f "$FONT_SRC" ]]; then
    cp "$FONT_SRC" "$FONT_DEST"
    echo "* Font copied to ~/Library/Fonts"
  else
    echo "⚠️ Font file not found at $FONT_SRC"
  fi
}

customize_screenshots() {
  echo "* customizing screenshots directory 📷 *"
  newline

  mkdir -p "$HOME/screenshots"
  defaults write com.apple.screencapture location "$HOME/screenshots"
  killall SystemUIServer
}

main() {
  install_homebrew
  install_dotfiles
  initialize_tmux
  install_nerdfont
  customize_screenshots

  echo "* setup complete 🎉 *"
}

main
