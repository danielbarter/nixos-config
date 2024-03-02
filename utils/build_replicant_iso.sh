build_new_replicant_iso() {
    echo "packing up nixos configuration"

    # remove old encrypted config, if it exits
    rm -f /tmp/nixos.zip.gpg

    sudo zip -r /tmp/nixos.zip /etc/nixos
    gpg -c /tmp/nixos.zip
    sudo rm /tmp/nixos.zip

    echo "generating iso"
    nix build /etc/nixos#replicant-iso --impure
}


read -p "Building a new replicant iso. Continue (y/n)? " choice
case "$choice" in
    y|Y ) build_new_replicant_iso;;
    n|N ) echo "doing nothing";;
    * ) echo "invalid";;
esac


