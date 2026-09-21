# Secrets checklist

The rotation utility changes files only. It never runs Git or rebuilds a host.

## Rotate one host's SSH key

- [ ] On the host whose key is changing, run `./utils/rotate ssh`.
- [ ] Review and distribute `secrets/<host>.json` and `keys/ssh/<host>.pub`.
- [ ] Build and switch the other two hosts so they accept the replacement key.
- [ ] Build and switch the rotating host last.
- [ ] Test user SSH and `ssh://nix-ssh@<host>` in both directions.

## Rotate one host's Nix signing key

- [ ] On the signing host, run `./utils/rotate nix`.
- [ ] Review and distribute `secrets/<host>.json` and `keys/nix/<host>.pub`.
- [ ] Build and switch all three hosts.
- [ ] On the signing host, run `doas nix store sign --all --key-file /run/secrets/nix-signing`.
- [ ] Test a store query or copy from another host.

## Rotate one host's Passage identity

- [ ] Start with clean `/etc/nixos` and password-store working trees.
- [ ] On the host whose identity is changing, run `./utils/rotate passage`.
- [ ] Review and distribute `secrets/<host>.json`, `keys/passage/<host>.pub`, and the password-store changes.
- [ ] Confirm `passage show <entry>` works on the other two hosts.
- [ ] Build and switch the rotating host, open a fresh shell, and confirm it can decrypt the store.

## Rotate WireGuard between Blaze and the phone

- [ ] Use LAN or console access to Blaze.
- [ ] Generate a replacement private key on Blaze with `wg genkey`; derive its public key with `wg pubkey`.
- [ ] Replace `wireguard` in `secrets/blaze.json` and `keys/wireguard/blaze.pub`.
- [ ] Generate a replacement key on the phone and replace `keys/wireguard/phone.pub` with its public key.
- [ ] Put Blaze's new public key in the phone tunnel and build and switch Blaze.
- [ ] Turn off phone Wi-Fi, connect the VPN, and test LAN access.

## Edit another secret

- [ ] Enter the tools shell with `nix develop .#secrets`.
- [ ] Run `doas env "PATH=$PATH" "TMPDIR=$XDG_RUNTIME_DIR" SOPS_AGE_KEY_FILE=/cold/age/key.agekey sops "secrets/$(hostname).json"`.
- [ ] Build with `nixos-rebuild build --flake ".#$(hostname)"`.
- [ ] Switch with `doas nixos-rebuild switch --flake ".#$(hostname)"`.
- [ ] Verify the affected service and distribute the encrypted change.
