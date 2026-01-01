## Introduction
This repository contains all the default configurations and packages that I prefer to have in place before I start building software. Like many others, having set up many systems over the years I've leaned into automation.

This repo is largely inspired by a [blog post](https://www.atlassian.com/git/tutorials/dotfiles) I found from Atlassian (inspired by other blog posts) that uses a bare git repo at its core. Having reviewed this along with other types of solutions (e.g., [chezmoi](https://www.chezmoi.io)) I determined that a bare git repo along with an installation scrypt gave me the best flexibility while keeping the process simple.

## What is Included?
The install for this dotfiles repo performs the following steps:
- Install [Homebrew](https://brew.sh)
- Copy all the dotfiles within this repo
- Install all the brews/casks/etc. from my [Brewfile](https://docs.brew.sh/Brew-Bundle-and-Brewfile)
- Install and set up my tmux configuration using the [Tmux Plugin Manager](https://github.com/tmux-plugins/tpm)
- Install and set up my vim configuration using [Vundle](https://github.com/VundleVim/Vundle.vim) (i.e., a vim plugin manager)
- Load various customizations for iTerm and MacOS usage.

## Installation
Run the install script from your terminal by executing the following command:

```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/imacomber/dotfiles/refs/heads/main/install.sh)"
```

## Uninstall
Should you need to remove everything that this script installs you can safely run the following command from your terminal:

```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/imacomber/dotfiles/refs/heads/main/uninstall.sh)"
```

> [!TIP]  
> The above command only removes the dotfiles (and a couple of small customizations). If you also would like to remove all the brews/casks/etc. and Homebrew itself you will need to preprend that command with the `REMOVE_HOMEBREW=1` environment variable.
