# set permissions
chown -R danielbarter /etc/nixos
chgrp -R users /etc/nixos

# 660 for all files not in secrets
for file in $(find /etc/nixos -print)
do
    chmod 660 $file
done


# 770 for files in utils
for file in $(find /etc/nixos/utils -type f -print)
do
    chmod 770 $file
done

# 755 for directories
for file in $(find /etc/nixos -type d -print)
do
    chmod 775 $file
done

