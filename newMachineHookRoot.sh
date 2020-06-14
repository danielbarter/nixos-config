# setting up root home directory
# run as root
# run before newMachineHookUser.sh as it sets a bunch of permissions


chown -R danielbarter /etc/nixos
chgrp -R users /etc/nixos
chmod 600 /etc/nixos/secrets/gpg/*
chmod 600 /etc/nixos/secrets/ssh/*

ln -s /etc/nixos/secrets/ssh /root/.ssh
