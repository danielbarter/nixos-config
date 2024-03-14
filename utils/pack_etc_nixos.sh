pack_etc_nixos() {
    echo "packing up nixos configuration"

    # remove old encrypted config, if it exits
    rm -f /tmp/nixos.zip.gpg

    sudo zip -r /tmp/nixos.zip /etc/nixos
    gpg -c /tmp/nixos.zip
    sudo rm /tmp/nixos.zip
}


read -p "Packing up /etc/nixos. Continue (y/n)? " choice
case "$choice" in
    y|Y ) pack_etc_nixos;;
    n|N ) echo "doing nothing";;
    * ) echo "invalid";;
esac


