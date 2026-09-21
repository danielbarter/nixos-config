# Secrets checklist

## One-time move to per-host keys and Passage

- [ ] On Punky, Jasper, and Blaze, run `./utils/rotate ssh add`, `./utils/rotate nix add`, and `./utils/rotate passage add`.
- [ ] After each host, review and distribute its changed `secrets/<host>.json` and `keys/{ssh,nix,passage}/<host>-next.pub`. The utility never runs Git.
- [ ] Once all changes are present everywhere, build and switch all three hosts.
- [ ] On each host, run `./utils/rotate ssh apply`, `./utils/rotate nix apply`, and `./utils/rotate passage apply`.
- [ ] Distribute those changes and build and switch all three hosts again.
- [ ] On one host, run `./utils/rotate passage migrate`. Review and distribute the password-store changes yourself.
- [ ] Pull the converted password store on every host and confirm `passage show <entry>` works.
- [ ] On every host, run `./utils/rotate passage cleanup-gpg` and distribute the changed encrypted host files.
- [ ] On every host, run `./utils/rotate ssh retire` and `./utils/rotate nix retire`.
- [ ] Remove the finished shared key files under `keys/ssh/homelab-*.pub`, `keys/nix/homelab-*.pub`, and the old `keys/rotations/` receipts.
- [ ] Build and switch every host, then test SSH and Nix-store access in both directions.
- [ ] Keep an offline copy of the old GPG key for password-store history.

## Rotate one host's SSH or Nix key

- [ ] On that host, run `./utils/rotate ssh add` or `./utils/rotate nix add`.
- [ ] Distribute the changed encrypted host file and `keys/<kind>/<host>-next.pub`.
- [ ] Build and switch every host so all peers accept the new public key.
- [ ] On the key's host, run `./utils/rotate <kind> apply`.
- [ ] Distribute the changes and build and switch every host again.
- [ ] Run `./utils/rotate <kind> retire` on the key's host.
- [ ] Distribute the changes and build and switch every host to revoke the old key.

## Rotate one host's Passage identity

- [ ] On that host, run `./utils/rotate passage add`.
- [ ] Distribute the encrypted host file and `keys/passage/<host>-next.pub`, then build and switch every host.
- [ ] On that host, run `./utils/rotate passage apply` and distribute the changes.
- [ ] On one machine with the password store, run `./utils/rotate passage reencrypt` and distribute the password-store changes yourself.
- [ ] Confirm `passage show <entry>` works on every host.
- [ ] On the identity's host, run `./utils/rotate passage retire` and distribute the changes.
- [ ] Build and switch every host.

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
