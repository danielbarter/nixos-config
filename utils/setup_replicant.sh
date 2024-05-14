setup_replicant_iso() {
    echo "set root password:"
    passwd root

    echo "set user password:"
    passwd danielbarter

    echo "unpacking nixos configuration"
    cd /etc
    # removing existing empty nixos config
    rmdir /etc/nixos
    gpg /etc/nixos.zip.gpg
    unzip /etc/nixos.zip

    cd /etc/nixos

    # set permissions for /etc/nixos
    source /etc/nixos/utils/set_permissions.sh

    # setup home
    source /etc/nixos/utils/home_setup.sh

    # symlink for ssh private key is now resolvable, so we need
    # to restart sshd
    systemctl restart sshd.service

    echo "all done!"
}

read -p "Setting up replicant iso. Continue (y/n)? " choice
case "$choice" in
    y|Y ) setup_replicant_iso;;
    n|N ) echo "doing nothing";;
    * ) echo "invalid";;
esac



