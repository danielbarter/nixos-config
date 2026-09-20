# Secrets checklist

## Before rotating

- [ ] Distribute the updated utility and Nix configuration to Punky, Jasper, and Blaze.
- [ ] Run commands as `danielbarter` from `/etc/nixos` in a normal terminal.
- [ ] Keep a backup of each host's `/cold/age/key.agekey` outside Git.
- [ ] Handle Git yourself: the utility does not stage, commit, push, or pull.
- [ ] Work on one key type and host at a time; distribute each host's changes before continuing on the next.

## Shared SSH or Nix key

- [ ] On the first host, run `./utils/rotate ssh add` (use `nix` instead of `ssh` for signing keys).
- [ ] Track the new public key, `keys/rotations/<kind>.json`, `secrets/rotations/<kind>.json`, and the changed `secrets/<host>.json`. New files must be tracked before the Git-backed flake can include them.
- [ ] Run `./utils/rotate ssh apply`. It builds and switches with both private keys active; SSH tries the new key first, and Nix signs with both keys.
- [ ] Review, commit, and distribute the changes, including the updated progress file.
- [ ] On each remaining host, pull the changes, run `add`, track any new files, run `apply`, and distribute its changes. The same shared replacement is reused.
- [ ] Run `./utils/rotate ssh status` and confirm all three hosts have applied the new key.
- [ ] Rebuild and replace Replicant images so they accept the new public key.
- [ ] For Nix, re-sign any separate archives/caches that still rely solely on the old key. `apply` already signs all local store paths with both keys.
- [ ] On each host, pull the latest changes and run `./utils/rotate ssh retire`. It verifies the new key works, removes the old private/public key, and rebuilds that host.
- [ ] Review and distribute each host's retirement changes, including deleted files. The last host removes the shared encrypted replacement file.
- [ ] Rebuild Replicant images again to remove their old public-key authorization/trust.

## GPG encryption subkey

- [ ] On the first host, run `./utils/rotate gpg add`. If prompted to select a primary key, use `--fingerprint FULL_FINGERPRINT` for the key used by `pass`.
- [ ] Track the generated public export, rotation files, and changed host secret file; run `./utils/rotate gpg apply`.
- [ ] Distribute the changes and repeat `add` then `apply` on each remaining host. Old subkeys and unrelated keys are retained.
- [ ] Wait until all hosts have applied the new subkey before changing or synchronizing passwords.
- [ ] On a host with the password store, pull the latest progress file and run `./utils/rotate gpg retire`. It re-encrypts and verifies entries while preserving nested recipients and `.gpg-id` files. Update any explicit `!` subkey pins first.
- [ ] Review and distribute the configuration changes and re-encrypted password store yourself.
- [ ] Retain old private GPG subkeys for historical password-store revisions.

## WireGuard: Blaze and phone

- [ ] Use LAN or console access to Blaze.
- [ ] If rotating the phone's key too, generate it on the phone and copy only its public key to a file on Blaze.
- [ ] Run `./utils/rotate wireguard` on Blaze. Add `--phone-public-key /path/to/phone.pub` if the phone has a new key.
- [ ] Set the printed Blaze public key as the phone tunnel's server public key.
- [ ] Review and track the changed `secrets/blaze.json` and `keys/wireguard/` files.
- [ ] Run `nixos-rebuild build --flake .#blaze`, then `doas nixos-rebuild switch --flake .#blaze`.
- [ ] Turn off the phone's Wi-Fi, connect the VPN, and test access to the LAN.
- [ ] Commit and distribute the changed encrypted secret and public keys.

## Other secret edits

- [ ] Enter the tools shell: `nix develop .#secrets`.
- [ ] Edit the local encrypted file: `doas env "PATH=$PATH" "TMPDIR=$XDG_RUNTIME_DIR" SOPS_AGE_KEY_FILE=/cold/age/key.agekey sops "secrets/$(hostname).json"`.
- [ ] Build and switch: `nixos-rebuild build --flake ".#$(hostname)"`, then `doas nixos-rebuild switch --flake ".#$(hostname)"`.
- [ ] Verify the affected service and commit/distribute the encrypted changes.
