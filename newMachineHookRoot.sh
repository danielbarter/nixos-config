# setting up root home directory
# run as root
# run before newMachineHookUser.sh as it sets a bunch of permissions



chown -R danielbarter /etc/nixos
chgrp -R wheel /etc/nixos

# LAN cache private key needs to be owned by nix-serve
chown nix-serve /etc/nixos/secrets/binary-cache/cache-priv-key.pem
chgrp nix-serve /etc/nixos/secrets/binary-cache/cache-priv-key.pem

for file in $(find /etc/nixos/secrets -type f)
do
    chmod 600 $file
done


for file in $(find /etc/nixos/secrets -type d)
do
    chmod 700 $file
done
