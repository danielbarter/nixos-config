# setting up home directory
# run as danielbarter

# symlink emacs and vim config into home
ln -s /etc/nixos/dotfiles/emacs/emacs.el /home/danielbarter/.emacs.el
ln -s /etc/nixos/dotfiles/vim/vimrc /home/danielbarter/.vimrc

# symlink shell config files into home
ln -s /etc/nixos/dotfiles/alacritty/alacritty.yml /home/danielbarter/.alacritty.yml
ln -s /etc/nixos/dotfiles/alacritty/bashrc /home/danielbarter/.bashrc
ln -s /etc/nixos/dotfiles/alacritty/bash_profile /home/danielbarter/.bash_profile

# installing mako config so we can let it be managed by dbus activation
mkdir -p /home/danielbarter/.config/mako
ln -s /etc/nixos/dotfiles/sway/config_mako /home/danielbarter/.config/mako/config

# import gpg keys
gpg --import /etc/nixos/secrets/gpg/privkey.asc /etc/nixos/secrets/gpg/public.asc

# grab passwords or create a new password repo
git clone git@github.com:danielbarter/password_store.git /home/danielbarter/.password-store
