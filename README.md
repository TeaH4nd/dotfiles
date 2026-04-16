# Dotfiles

Personal Linux shell and editor configuration managed with GNU Stow.

## What is in this repo

This repository is organized into Stow packages:

- `bash/` - Bash defaults (`.bashrc`, `.bash_aliases`, `.bash_profile`)
- `vim/` - Vim config (`.vimrc`, `.vim/`)
- `work/` - Optional machine- or work-specific overrides (`.bashrc_local`)
- `run.sh` - Bootstrap script to install dependencies, back up conflicting files, and stow packages

## Requirements

- Linux (tested with Debian/Ubuntu style package names)
- `git`
- `stow`
- `vim`

Install basics manually (if needed):

```bash
sudo apt update
sudo apt install -y git stow vim
```

## Quick start

Clone into your home directory (recommended for dotfiles):

```bash
cd ~
git clone https://github.com/TeaH4nd/dotfiles.git
cd dotfiles
```

Then run the bootstrap script:

```bash
chmod +x run.sh
./run.sh
```

What `run.sh` does:

- pulls latest changes from `main`
- verifies `vim`, `stow`, and `nerdfetch`
- moves conflicting real files into a timestamped backup directory
- runs Stow for `bash` and `vim`

## GNU Stow usage example

The basic idea is simple:

1. Create a `~/dotfiles` directory.
2. Inside it, create one subdirectory per program (`bash`, `vim`, `work`, etc.).
3. Move each config file into the matching package directory while preserving the path it would normally have under your home directory.
4. Run `stow <package>` from `~/dotfiles` and Stow creates symlinks back into `$HOME`.

If a config normally lives directly in your home directory, place it at the package root:

- `~/.bashrc` -> `~/dotfiles/bash/.bashrc`
- `~/.vimrc` -> `~/dotfiles/vim/.vimrc`

If a config normally lives below XDG paths, keep that structure inside the package:

- `~/.config/<pkg>/...` -> `~/dotfiles/<pkg>/.config/<pkg>/...`
- `~/.local/share/<pkg>/...` -> `~/dotfiles/<pkg>/.local/share/<pkg>/...`

Example before organizing:

```text
home/
	user/
		.config/
			appx/
				[...files]
		.local/
			share/
				appx/
					[...files]
		.vim/
			[...files]
		.bashrc
		.bash_profile
		.vimrc
```

Example after moving files into dotfiles packages:

```text
home/
	user/
		dotfiles/
			bash/
				.bashrc
				.bash_profile
			vim/
				.vim/
					[...files]
				.vimrc
			appx/
				.config/
					appx/
						[...files]
				.local/
					share/
						appx/
							[...files]
```

Then stow each package:

```bash
cd ~/dotfiles
stow -v -t "$HOME" bash
stow -v -t "$HOME" vim
stow -v -t "$HOME" appx
```

At that point, your home directory has symlinks in the usual locations, while the real files stay organized in one version-controlled repository. This also makes multi-machine setups easier: keep all packages in the repo, but only stow the ones needed on each machine.

Common commands:

```bash
# Remove symlinks for a package
stow -D -v -t "$HOME" bash

# Re-stow a package after changes
stow -R -v -t "$HOME" vim
```

### Typical workflow

```bash
# 1) Edit files in the repo package directories
nvim ~/dotfiles/bash/.bashrc

# 2) Re-stow package so links are up to date
cd ~/dotfiles
stow -R -v -t "$HOME" bash

# 3) Reload shell
source ~/.bashrc
```

## Handling conflicts safely

If a target file already exists in your home directory and is not a symlink, Stow can fail with a conflict.

Options:

- use `./run.sh` (backs up conflicting files before stowing)
- manually move existing files to a backup location, then run Stow again

Example:

```bash
mkdir -p ~/.dotfiles_backup
mv ~/.bashrc ~/.dotfiles_backup/
cd ~/dotfiles
stow -v -t "$HOME" bash
```

## Optional package: work

The `work/` package contains local overrides like `.bashrc_local`.

Enable it only on machines where you need it:

```bash
cd ~/dotfiles
stow -v -t "$HOME" work
```

## Updating

```bash
cd ~/dotfiles
git pull origin main
stow -R -v -t "$HOME" bash vim
```

## Uninstall (remove symlinks only)

```bash
cd ~/dotfiles
stow -D -v -t "$HOME" bash vim work
```

This removes symlinks managed by Stow. It does not delete your repository.