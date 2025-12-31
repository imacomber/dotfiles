#!/usr/bin/env bash

set -euo pipefail

TMUX_PREFIX="C-b"

LOGFILE="$HOME/setup.log"
exec > >(tee -a "$LOGFILE") 2>&1

newline() {
  echo
}

config() {
  /usr/bin/git --git-dir="$HOME/.cfg/" --work-tree="$HOME" "$@"
}

ensure_brew_env() {
  # Ensure Homebrew is on PATH for *this* script execution.
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  elif command -v brew >/dev/null 2>&1; then
    # brew already on PATH; still useful to pull in its env vars
    eval "$(brew shellenv)"
  else
    return 1
  fi

  # Make sure the shell refreshes its command hash table (bash/zsh behavior)
  hash -r 2>/dev/null || true
}

install_homebrew() {
  echo "* installing homebrew 🍺 *"
  newline

  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if ! ensure_brew_env; then
    echo "❌ homebrew not found after install; exiting."
    exit 1
  fi

  newline
  echo "* homebrew successfully installed 🍻 *"
  newline
}

install_dotfiles() {
  echo "* cloning dotfiles repo 🐙 *"
  newline

  if [[ -d "$HOME/.cfg" ]]; then
    echo "⚠️ dotfiles repo already exists; skipping clone."
  else
    git clone --bare https://github.com/imacomber/dotfiles.git "$HOME/.cfg"
  fi

  if config checkout; then
    echo "* successfully cloned and checked out repo ✅ *"
    newline
  else
    echo "* backing up existing dotfiles 💾 *"
    newline

    mkdir -p "$HOME/.config-backup"
    config checkout 2>&1 | grep -E "\s+\." | awk '{print $1}' | while read -r file; do
      mv "$HOME/$file" "$HOME/.config-backup/$file"
    done
  fi

  config checkout
  config config status.showUntrackedFiles no

  echo "* successfully installed dotfiles ✅ *"
}

bundle_brewfile() {
  echo "* bundling homebrew formulae and casks 🍻 *"
  newline

  ensure_brew_env || true
  brew bundle || echo "⚠️ brew bundle failed (might be missing Brewfile)"

  ensure_brew_env || true
}

setup_tmux() {
  echo "* setting up tmux 🪟 *"
  newline

  ensure_brew_env || true

  if [[ ! -f "$HOME/.tmux.conf" ]]; then
    echo "⚠️ ~/.tmux.conf not found; skipping tmux setup."
    return 0
  fi

  # Locate tmux (works for Intel + Apple Silicon + generic PATH)
  local tmux_bin=""
  if command -v tmux >/dev/null 2>&1; then
    tmux_bin="$(command -v tmux)"
  elif command -v brew >/dev/null 2>&1; then
    tmux_bin="$(brew --prefix tmux 2>/dev/null)/bin/tmux" || true
  fi

  if [[ -z "$tmux_bin" || ! -x "$tmux_bin" ]]; then
    echo "⚠️ tmux not found; skipping."
    return 0
  fi

  # Bootstrap TPM if your config expects it
  # (Safe to run even if you don't use TPM—it's a no-op unless referenced.)
  local tpm_dir="$HOME/.tmux/plugins/tpm"
  if grep -qE "@plugin[[:space:]]+['\"]tmux-plugins/tpm['\"]" "$HOME/.tmux.conf"; then
    if [[ ! -d "$tpm_dir" ]]; then
      echo "* bootstrapping TPM (tmux plugin manager) 🔌 *"
      mkdir -p "$HOME/.tmux/plugins"
      git clone https://github.com/tmux-plugins/tpm "$tpm_dir" || true
    fi
  fi

  # Run everything inside a temporary detached tmux session so install.sh stays non-interactive
  local session="__tmux_setup__"

  "$tmux_bin" has-session -t "$session" 2>/dev/null && "$tmux_bin" kill-session -t "$session" || true
  "$tmux_bin" new-session -d -s "$session"

  # Load tmux config
  "$tmux_bin" source-file "$HOME/.tmux.conf" || true

  # Trigger TPM install (<prefix> + I)
  # This is the same as pressing C-b then Shift+i.
  "$tmux_bin" send-keys -t "$session" "$TMUX_PREFIX" I

  # Allow time for TPM to clone plugins (network-dependent)
  # If you want to be stricter, increase this to 5–10 seconds.
  sleep 3

  # Tear down the temporary session
  "$tmux_bin" kill-session -t "$session" || true

  echo "* tmux configured and plugins installed ✅ *"
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

setup_iterm2_profile() {
  echo "* configuring iTerm2 profile (dynamic profile + default) *"
  newline

  local PROFILE_SRC="$HOME/iterm_profiles.json"

  if [[ ! -f "$PROFILE_SRC" ]]; then
    echo "⚠️ iTerm2 profile JSON not found at: $PROFILE_SRC"
    echo "   Skipping iTerm2 profile setup."
    return 0
  fi

  # Ensure jq exists (brew bundle *may* already install it, but this makes the step robust).
  ensure_brew_env || true
  if ! command -v jq >/dev/null 2>&1; then
    if command -v brew >/dev/null 2>&1; then
      brew install jq || true
    fi
  fi
  if ! command -v jq >/dev/null 2>&1; then
    echo "⚠️ jq is required to read the iTerm2 profile GUID; skipping."
    return 0
  fi

  # Quit iTerm2 if it's running so it will reload preferences/profiles cleanly.
  osascript -e 'tell application "iTerm2" to quit' >/dev/null 2>&1 || true

  # Install as a Dynamic Profile so iTerm2 auto-imports it on launch.
  local DYNAMIC_DIR="$HOME/Library/Application Support/iTerm2/DynamicProfiles"
  mkdir -p "$DYNAMIC_DIR"
  cp -f "$PROFILE_SRC" "$DYNAMIC_DIR/iterm_profiles.json"

  # Extract the first profile GUID and set it as the iTerm2 default profile.
  # (If you export multiple profiles, adjust the jq selector.)
  local GUID
  GUID="$(jq -r '.Profiles[0].Guid // empty' "$PROFILE_SRC")"

  if [[ -z "$GUID" ]]; then
    echo "⚠️ Could not find .Profiles[0].Guid in $PROFILE_SRC; skipping default-profile setting."
    return 0
  fi

  # Set default profile GUID (new windows/tabs will use this profile).
  defaults write com.googlecode.iterm2 "Default Bookmark Guid" -string "$GUID"

  echo "* iTerm2 profile installed and default set ✅ (Guid: $GUID) *"
}

main() {
  install_homebrew
  install_dotfiles
  bundle_brewfile
  setup_tmux
  install_nerdfont
  customize_screenshots
  setup_iterm2_profile

  echo "* setup complete 🎉 *"
}

main
