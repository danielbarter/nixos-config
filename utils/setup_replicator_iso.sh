echo "set root password:"
passwd root

echo "set user password:"
passwd danielbarter

echo "unpacking nixos configuration"
cd /tmp
cp /iso/nixos.zip.gpg /tmp/nixos.zip.gpg
gpg nixos.zip.gpg
unzip nixos.zip

rmdir /etc/nixos
mv /tmp/etc/nixos /etc/nixos

cd /etc/nixos
source /etc/nixos/utils/set_permissions.sh
