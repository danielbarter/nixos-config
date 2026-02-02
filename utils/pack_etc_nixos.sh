pack_etc_nixos() {
    echo "packing up nixos configuration"

    # remove old zip if it exists
    rm -f /tmp/nixos.zip

    # remove result symlink, so we don't end up with an image in image situation
    rm -f /etc/nixos/result

    # zip up everything except the .git folder, since that contains a lot of files
    doas zip -r /tmp/nixos.zip /etc/nixos -x /etc/nixos/.git\*
}

read -p "Packing up /etc/nixos. Continue (y/n)? " choice
case "$choice" in
    y|Y ) pack_etc_nixos;;
    n|N ) echo "doing nothing";;
    * ) echo "invalid";;
esac


