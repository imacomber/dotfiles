#!/usr/bin/env bash
set -euo pipefail

# uninstall.sh
#
# Removes the changes made by install.sh:
# - Uninstalls Claude Code plugins and CLI (settings/CLAUDE.md are removed with dotfiles)
# - Cleans up legacy MCP config (~/.claude/mcp.json) if present
# - Removes rails-mcp-server gem
# - Removes dotfiles checked out from the bare repo (~/.cfg)
# - Optionally uninstalls Homebrew and/or Brewfile-installed packages
# - Removes the custom Nerd Font that was copied
# - Reverts the macOS screenshots location setting and removes ~/screenshots
# - Removes ~/setup.log (created by install.sh)
#
# Usage:
#   ./uninstall.sh
#
# Optional env flags:
#   REMOVE_BREW_BUNDLE=1   -> attempt to uninstall Brewfile formulae/casks/taps
#   REMOVE_HOMEBREW=1      -> run the official Homebrew uninstall script (also implies brew bundle removal attempt)
#   KEEP_CLAUDE=1          -> skip Claude Code uninstallation (plugins, settings, CLI)

exec > >(tee /dev/stdout) 2>&1

newline() { echo; }

config() {
  /usr/bin/git --git-dir="$HOME/.cfg/" --work-tree="$HOME" "$@"
}

have_cmd() { command -v "$1" >/dev/null 2>&1; }

detect_brew() {
  if [[ -x /opt/homebrew/bin/brew ]]; then
    echo "/opt/homebrew/bin/brew"
  elif [[ -x /usr/local/bin/brew ]]; then
    echo "/usr/local/bin/brew"
  elif have_cmd brew; then
    command -v brew
  else
    echo ""
  fi
}

load_brew_env() {
  local brew_bin
  brew_bin="$(detect_brew)"
  [[ -n "$brew_bin" ]] || return 0

  if [[ "$brew_bin" == "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ "$brew_bin" == "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

remove_dotfiles_checkout() {
  echo "* removing dotfiles checkout 🧹 *"
  newline

  if [[ ! -d "$HOME/.cfg" ]]; then
    echo "⚠️ ~/.cfg not found; skipping dotfiles removal."
    return 0
  fi

  # Remove files that were checked out from the bare repo.
  # (This is the most accurate way to remove what install.sh installed/checked out.)
  local tracked_files
  tracked_files="$(config ls-tree -r --name-only HEAD || true)"

  if [[ -n "$tracked_files" ]]; then
    echo "$tracked_files" | while IFS= read -r relpath; do
      [[ -n "$relpath" ]] || continue
      local target="$HOME/$relpath"

      # Only remove if it exists (and is a file/symlink). Do not rm -rf arbitrary directories.
      if [[ -L "$target" || -f "$target" ]]; then
        rm -f "$target"
      fi
    done

    # Best-effort cleanup of empty directories created by tracked files.
    # (Safe: rmdir only removes empty dirs.)
    echo "$tracked_files" | while IFS= read -r relpath; do
      [[ -n "$relpath" ]] || continue
      local dir
      dir="$(dirname "$HOME/$relpath")"
      while [[ "$dir" != "$HOME" && "$dir" != "/" ]]; do
        rmdir "$dir" 2>/dev/null || break
        dir="$(dirname "$dir")"
      done
    done
  else
    echo "⚠️ could not enumerate tracked files; skipping removal of checked-out dotfiles."
  fi

  # Remove the bare repo directory last
  rm -rf "$HOME/.cfg"

  echo "* dotfiles removed ✅ *"
}

remove_brewfile_software() {
  echo "* uninstalling Brewfile-managed software 🍺 *"
  newline

  load_brew_env
  if ! have_cmd brew; then
    echo "⚠️ brew not found; skipping Brewfile uninstall."
    return 0
  fi

  local brewfile=""
  if [[ -f "$HOME/Brewfile" ]]; then
    brewfile="$HOME/Brewfile"
  elif [[ -f "$HOME/.Brewfile" ]]; then
    brewfile="$HOME/.Brewfile"
  fi

  if [[ -z "$brewfile" ]]; then
    echo "⚠️ no Brewfile found at ~/Brewfile or ~/.Brewfile; skipping."
    return 0
  fi

  echo "Using Brewfile: $brewfile"
  newline

  # Parse Brewfile for common directives:
  #   brew "formula"
  #   cask "app"
  #   tap "repo"
  #
  # We intentionally skip `mas` entries (Mac App Store) because sign-in is required and behavior varies.
  local formulae=()
  local casks=()
  local taps=()

  while IFS= read -r line; do
    # Strip comments
    line="${line%%#*}"
    # Trim
    line="$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    [[ -n "$line" ]] || continue

    if [[ "$line" =~ ^brew[[:space:]]+\"([^\"]+)\" ]]; then
      formulae+=("${BASH_REMATCH[1]}")
    elif [[ "$line" =~ ^brew[[:space:]]+\'([^\']+)\' ]]; then
      formulae+=("${BASH_REMATCH[1]}")
    elif [[ "$line" =~ ^cask[[:space:]]+\"([^\"]+)\" ]]; then
      casks+=("${BASH_REMATCH[1]}")
    elif [[ "$line" =~ ^cask[[:space:]]+\'([^\']+)\' ]]; then
      casks+=("${BASH_REMATCH[1]}")
    elif [[ "$line" =~ ^tap[[:space:]]+\"([^\"]+)\" ]]; then
      taps+=("${BASH_REMATCH[1]}")
    elif [[ "$line" =~ ^tap[[:space:]]+\'([^\']+)\' ]]; then
      taps+=("${BASH_REMATCH[1]}")
    elif [[ "$line" =~ ^mas[[:space:]]+ ]]; then
      echo "⚠️ skipping Mac App Store entry: $line"
    fi
  done < "$brewfile"

  if (( ${#casks[@]} )); then
    echo "Uninstalling casks (${#casks[@]})..."
    brew uninstall --cask --force "${casks[@]}" || true
    newline
  fi

  if (( ${#formulae[@]} )); then
    echo "Uninstalling formulae (${#formulae[@]})..."
    brew uninstall --force "${formulae[@]}" || true
    newline
  fi

  if (( ${#taps[@]} )); then
    echo "Untapping taps (${#taps[@]})..."
    # Avoid failing hard if a tap is already gone or protected.
    for t in "${taps[@]}"; do
      brew untap "$t" || true
    done
    newline
  fi

  # Clean up dependencies and caches
  brew autoremove || true
  brew cleanup || true

  echo "* Brewfile uninstall attempt complete ✅ *"
}

uninstall_homebrew() {
  echo "* uninstalling Homebrew 🧨 *"
  newline

  load_brew_env
  if ! have_cmd brew && [[ ! -x /opt/homebrew/bin/brew && ! -x /usr/local/bin/brew ]]; then
    echo "⚠️ brew not found; skipping Homebrew uninstall."
    return 0
  fi

  # Homebrew's official uninstall script:
  # https://docs.brew.sh/FAQ#how-do-i-uninstall-homebrew
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)" || true

  echo "* Homebrew uninstall attempted ✅ *"
}

remove_nerdfont() {
  echo "* removing custom nerd font 🤓 *"
  newline

  local font_dest="$HOME/Library/Fonts/FiraCodeNerdFontMono-Light.ttf"

  if [[ -f "$font_dest" ]]; then
    rm -f "$font_dest"
    echo "removed: $font_dest"
  else
    echo "ℹ️ font not found at $font_dest; skipping."
  fi
}

revert_screenshots() {
  echo "* reverting screenshots customization 📷 *"
  newline

  # Remove the custom location key; macOS will revert to its default behavior.
  defaults delete com.apple.screencapture location >/dev/null 2>&1 || true
  killall SystemUIServer >/dev/null 2>&1 || true

  # Remove directory created by install.sh (only if empty or if user wants it gone).
  if [[ -d "$HOME/screenshots" ]]; then
    # Try to remove if empty; otherwise leave it (safer).
    rmdir "$HOME/screenshots" 2>/dev/null || echo "⚠️ ~/screenshots is not empty; leaving it in place."
  fi
}

remove_claude_plugins() {
  echo "* uninstalling Claude Code plugins 🧩 *"
  newline

  if ! have_cmd claude; then
    echo "⚠️  claude not found; skipping plugin uninstall."
    return 0
  fi

  local official_plugins=(
    ruby-lsp
    slack
    context7
    code-review
    github
    playwright
  )

  for plugin in "${official_plugins[@]}"; do
    echo "Uninstalling $plugin plugin..."
    claude plugins uninstall "$plugin" --scope user \
      || echo "⚠️  $plugin uninstall failed or not installed."
  done

  echo "Uninstalling superpowers-ruby plugin..."
  claude plugins uninstall superpowers-ruby@superpowers-ruby --scope user \
    || echo "⚠️  superpowers-ruby uninstall failed or not installed."

  echo "Removing superpowers-ruby marketplace..."
  claude plugins marketplace remove superpowers-ruby \
    || echo "⚠️  superpowers-ruby marketplace removal failed or not registered."

  echo "* Claude Code plugins uninstalled ✅ *"
}

remove_legacy_mcp_config() {
  # Clean up legacy MCP config if it exists from a previous install
  local mcp_file="$HOME/.claude/mcp.json"
  if [[ -f "$mcp_file" ]]; then
    echo "* removing legacy MCP config 🔌 *"
    rm -f "$mcp_file"
    echo "removed: $mcp_file"
  fi
}

remove_rails_mcp() {
  echo "* removing rails-mcp-server 🛤️ *"
  newline

  if ! have_cmd gem; then
    echo "⚠️  gem not found; skipping rails-mcp-server removal."
    return 0
  fi

  if gem list --installed rails-mcp-server >/dev/null 2>&1; then
    gem uninstall rails-mcp-server --executables || echo "⚠️  rails-mcp-server uninstall failed."
    echo "* rails-mcp-server removed ✅ *"
  else
    echo "ℹ️  rails-mcp-server not installed; skipping."
  fi
}

uninstall_claude_code() {
  echo "* uninstalling Claude Code CLI 🤖 *"
  newline

  if ! have_cmd claude; then
    echo "⚠️  claude not found; skipping CLI uninstall."
    return 0
  fi

  # Claude Code provides a built-in uninstall command
  claude uninstall || echo "⚠️  claude uninstall command failed; you may need to remove it manually."

  hash -r 2>/dev/null || true

  echo "* Claude Code CLI uninstalled ✅ *"
}

remove_setup_log() {
  if [[ "${KEEP_LOG:-0}" == "1" ]]; then
    echo "ℹ️ KEEP_LOG=1 set; leaving $HOME/setup.log in place."
    return 0
  fi

  if [[ -f "$HOME/setup.log" ]]; then
    rm -f "$HOME/setup.log"
    echo "* removed $HOME/setup.log 🧾 *"
  fi
}

main() {
  # Brewfile-installed software (optional)
  if [[ "${REMOVE_BREW_BUNDLE:-0}" == "1" || "${REMOVE_HOMEBREW:-0}" == "1" ]]; then
    remove_brewfile_software
    newline
  else
    echo "ℹ️ skipping Brewfile uninstall (set REMOVE_BREW_BUNDLE=1 to enable)."
    newline
  fi

  # Homebrew itself (optional, strongest action)
  if [[ "${REMOVE_HOMEBREW:-0}" == "1" ]]; then
    uninstall_homebrew
    newline
  else
    echo "ℹ️ skipping Homebrew uninstall (set REMOVE_HOMEBREW=1 to enable)."
    newline
  fi

  # Claude Code (plugins → settings → rails-mcp → CLI, in dependency order)
  if [[ "${KEEP_CLAUDE:-0}" == "1" ]]; then
    echo "ℹ️ skipping Claude Code uninstall (KEEP_CLAUDE=1 set)."
    newline
  else
    remove_claude_plugins
    newline

    remove_legacy_mcp_config
    newline

    remove_rails_mcp
    newline

    uninstall_claude_code
    newline
  fi

  # Dotfiles installed by git bare checkout
  remove_dotfiles_checkout
  newline

  # Other local system tweaks performed by install.sh
  remove_nerdfont
  newline

  revert_screenshots
  newline

  remove_setup_log

  echo "* uninstall complete ✅ *"
}

main
