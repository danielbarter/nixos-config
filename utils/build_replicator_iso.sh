echo "packing up nixos configuration"
cd /tmp
sudo zip -r /tmp/nixos.zip /etc/nixos
gpg -c /tmp/nixos.zip
sudo rm /tmp/nixos.zip

echo "generating iso"
cd /etc/nixos
nix build .#x86_64-linux-iso -o /tmp/result --impure
rm /tmp/nixos.zip.gpg
cp /tmp/result/iso/nixos.iso /tmp
rm /tmp/result

echo "all done. iso is at /tmp/nixos.iso"
