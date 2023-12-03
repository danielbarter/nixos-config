# set permissions
chown -R danielbarter /etc/nixos
chgrp -R wheel /etc/nixos

# LAN cache private key needs to be owned by nix-serve
# if id nix-serve
# then
#     chown nix-serve /etc/nixos/secrets/binary-cache/cache-priv-key.pem
#     chgrp nix-serve /etc/nixos/secrets/binary-cache/cache-priv-key.pem
# fi

for file in $(find /etc/nixos/secrets -type f)
do
    chmod 600 $file
done


for file in $(find /etc/nixos/secrets -type d)
do
    chmod 755 $file
done

