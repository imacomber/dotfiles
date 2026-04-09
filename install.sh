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

setup_vim() {
  echo "* setting up Vim *"
  newline

  if ! command -v git >/dev/null 2>&1; then
    echo "⚠️ git not found; cannot install Vundle. Skipping."
    return 0
  fi

  local vundle_dir="$HOME/.vim/bundle/Vundle.vim"
  if [[ -d "$vundle_dir/.git" ]]; then
    echo "✅ Vundle already installed; skipping clone."
  else
    mkdir -p "$HOME/.vim/bundle"
    git clone https://github.com/VundleVim/Vundle.vim.git "$vundle_dir"
  fi

  if command -v vim >/dev/null 2>&1 && [[ -f "$HOME/.vimrc" ]]; then
    vim -E -s -u "$HOME/.vimrc" +PluginInstall +qall || true
    echo "* Vim plugins installed via Vundle ✅ *"
  else
    echo "⚠️ vim or ~/.vimrc not found; skipping Vundle PluginInstall."
  fi
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

install_claude_code() {
  echo "* installing Claude Code CLI 🤖 *"
  newline

  if type -P claude >/dev/null 2>&1; then
    echo "✅ Claude Code already installed at $(type -P claude); skipping."
    newline
    return 0
  fi

  curl -fsSL https://claude.ai/install.sh | bash
  hash -r 2>/dev/null || true

  echo "* Claude Code CLI installed ✅ *"
  newline
}

setup_rails_mcp() {
  echo "* setting up rails-mcp-server 🛤️ *"
  newline

  if ! command -v gem >/dev/null 2>&1; then
    echo "⚠️  gem not found; skipping rails-mcp-server install."
    newline
    return 0
  fi

  gem install rails-mcp-server

  echo "* rails-mcp-server gem installed ✅ *"
  newline
  echo "* configuring rails-mcp-server projects (interactive) *"
  newline

  rails-mcp-config

  echo "* downloading rails-mcp-server resources *"
  newline

  rails-mcp-server-download-resources rails
  rails-mcp-server-download-resources turbo
  rails-mcp-server-download-resources stimulus

  echo "* registering rails MCP server with Claude Code *"
  newline

  claude mcp add rails --scope user -- rails-mcp-server

  echo "* rails-mcp-server configured ✅ *"
  newline
}

setup_claude_plugins() {
  echo "* installing Claude Code plugins 🧩 *"
  newline

  if ! type -P claude >/dev/null 2>&1; then
    echo "⚠️  claude not found; skipping plugin install."
    newline
    return 0
  fi

  # Register the superpowers-ruby third-party marketplace
  echo "Registering superpowers-ruby marketplace..."
  claude plugins marketplace add lucianghinda/superpowers-ruby \
    || echo "⚠️  superpowers-ruby marketplace registration failed or already registered."

  # Official plugins (claude-plugins-official marketplace is built-in)
  local official_plugins=(
    ruby-lsp
    slack
    context7
    code-review
    github
    playwright
  )

  for plugin in "${official_plugins[@]}"; do
    echo "Installing $plugin plugin..."
    claude plugins install "$plugin" --scope user \
      || echo "⚠️  $plugin install failed or already installed."
  done

  # Third-party plugins
  echo "Installing superpowers-ruby plugin..."
  claude plugins install superpowers-ruby@superpowers-ruby --scope user \
    || echo "⚠️  superpowers-ruby install failed or already installed."

  if [[ ! -f "$HOME/.claude/CLAUDE.md" ]]; then
    echo "⚠️  ~/.claude/CLAUDE.md not found."
    echo "   If your dotfiles track it, run install_dotfiles first."
  else
    echo "✅ ~/.claude/CLAUDE.md present."
  fi

  newline
  echo "* Claude Code plugins installed ✅ *"
  newline
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
  setup_vim
  install_claude_code
  setup_rails_mcp
  setup_claude_plugins

  echo "* setup complete 🎉 *"
}

main
