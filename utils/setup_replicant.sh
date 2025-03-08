setup_replicant() {
    echo "set root password:"
    passwd root

    echo "set user password:"
    passwd danielbarter

    echo "unpacking nixos configuration"
    cp $REPLICANT_NIXOS_CONFIG /nixos.zip.gpg
    cd /
    # removing existing empty nixos config
    gpg /nixos.zip.gpg
    unzip /nixos.zip

    cd /etc/nixos

    # set permissions for /etc/nixos
    source /etc/nixos/utils/set_permissions.sh

    # setup home
    source /etc/nixos/utils/home_setup.sh

    # symlink for ssh private key is now resolvable, so we need
    # to restart sshd
    systemctl restart sshd.service

    # wiregaurd keys are now present, so restart systemd-networkd
    # to create wireguard interface
    systemctl restart systemd-networkd.service

    echo "all done!"
}

read -p "Setting up replicant. Continue (y/n)? " choice
case "$choice" in
    y|Y ) setup_replicant;;
    n|N ) echo "doing nothing";;
    * ) echo "invalid";;
esac



