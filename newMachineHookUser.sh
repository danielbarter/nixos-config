# setting up home directory
# run as danielbarter

gpg --import /etc/nixos/secrets/gpg/privkey.asc /etc/nixos/secrets/gpg/public.asc

# setup ssh
mkdir /home/danielbarter/.ssh
ln -s /etc/nixos/secrets/ssh/id_rsa /home/danielbarter/.ssh/
ln -s /etc/nixos/secrets/ssh/id_rsa.pub /home/danielbarter/.ssh
ln -s /etc/nixos/dotfiles/ssh/config /home/danielbarter/.ssh
mkdir /home/danielbarter/.ssh/sockets


ln -s /etc/nixos/dotfiles/emacs/emacs.el /home/danielbarter/.emacs.el

# IntelliJ won't read symbolic links which point outside its home directory
ln /etc/nixos/dotfiles/vim/vimrc /home/danielbarter/.vimrc
ln /etc/nixos/dotfiles/vim/ideavimrc /home/danielbarter/.ideavimrc

ln -s /etc/nixos/dotfiles/alacritty/alacritty.yml /home/danielbarter/.alacritty.yml
ln -s /etc/nixos/dotfiles/alacritty/bashrc /home/danielbarter/.bashrc
ln -s /etc/nixos/dotfiles/alacritty/bash_profile /home/danielbarter/.bash_profile

# installing mako config so we can let it be managed by dbus activation
mkdir -p /home/danielbarter/.config/mako
ln -s /etc/nixos/dotfiles/sway/config_mako /home/danielbarter/.config/mako/config

# grab passwords or create a new password repo
git clone git@github.com:danielbarter/password_store.git /home/danielbarter/.password-store
