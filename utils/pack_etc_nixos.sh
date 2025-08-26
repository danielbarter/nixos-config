pack_etc_nixos() {
    echo "packing up nixos configuration"

    # remove old encrypted config, if it exits
    rm -f /tmp/nixos.zip.gpg

    # remove result symlink, so we don't end up with an image in image situation
    rm -f /etc/nixos/result

    # zip up everything except the .git folder, since that contains a lot of files
    doas zip -r /tmp/nixos.zip /etc/nixos -x /etc/nixos/.git\*
    gpg --cipher-algo AES256 -c /tmp/nixos.zip
    doas rm /tmp/nixos.zip
}


read -p "Packing up /etc/nixos. Continue (y/n)? " choice
case "$choice" in
    y|Y ) pack_etc_nixos;;
    n|N ) echo "doing nothing";;
    * ) echo "invalid";;
esac


