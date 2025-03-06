# set permissions
chown -R danielbarter /etc/nixos
chgrp -R wheel /etc/nixos

# wireguard private keys only need to be read by root
chown -R systemd-network /etc/nixos/secrets/wireguard
chgrp -R systemd-network /etc/nixos/secrets/wireguard

# LAN cache private key needs to be owned by nix-serve
if id nix-serve
then
    chown nix-serve /etc/nixos/secrets/binary-cache/cache-priv-key.pem
    chgrp nix-serve /etc/nixos/secrets/binary-cache/cache-priv-key.pem
fi

# 660 for all files not in secrets
for file in $(find /etc/nixos -path /etc/nixos/secrets -prune -o -type f -print)
do
    chmod 660 $file
done

# 600 for all files in secrets
for file in $(find /etc/nixos/secrets -type f)
do
    chmod 600 $file
done

# 770 for files in utils
for file in $(find /etc/nixos/utils -type f -print)
do
    chmod 770 $file
done


for file in $(find /etc/nixos -type d)
do
    chmod 775 $file
done

