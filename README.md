## Installation
Run the following command from your terminal:

```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/imacomber/dotfiles/refs/heads/main/install.sh)"
```

## Uninstall
Should you need to remove everything that this script installs you can run the following command from your terminal (**Note**: the command below also deletes Homebrew, which is not the default experience; remove the `REMOVE_HOMEBREW` environment variable if you want to leave Homebrew):

```
REMOVE_HOMEBREW=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/imacomber/dotfiles/refs/heads/main/uninstall.sh)"
```
