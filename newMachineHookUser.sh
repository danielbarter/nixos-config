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
ln -s /etc/nixos/dotfiles/alacritty/alacritty.yml /home/danielbarter/.alacritty.yml
ln -s /etc/nixos/dotfiles/alacritty/bashrc /home/danielbarter/.bashrc

git clone git@github.com:danielbarter/password_store.git /home/danielbarter/.password-store

mkdir /home/danielbarter/.config
mkdir /home/danielbarter/.config/nixpkgs/
echo "{ allowUnfree = true; }" > /home/danielbarter/.config/nixpkgs/config.nix

# set up user environment
nix-env --remove-all -if /etc/nixos/danielbarterEnv.nix
