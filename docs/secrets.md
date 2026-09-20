# Secrets

Each physical host has one age identity at `/cold/age/key.agekey`. Its private
key never enters Git. The corresponding public recipient, ordinary public keys,
and SOPS-encrypted host secrets are committed to this repository.

`keys/` contains public material only: age recipients, authorized SSH keys, the
Nix signing public key, and WireGuard peer identities. Private material is
either the age identity on `/cold` or a value inside `secrets/<host>.json`.

At activation, sops-nix decrypts secrets into `/run/secrets`. `pass` remains the
normal package and continues to use `~/.gnupg`; a oneshot service imports the
deployed GPG export on boot and whenever that export changes.

The `replicant` images contain only public authorized SSH keys and the public
Nix signing key used to verify cache paths. Their password logins are locked,
and they do not receive a private SSH client key, Nix signing private key, or
`pass` key.

## One-time migration

First create an age recovery key on a separate offline device. Keep the private
key off every host and out of Git:

```sh
umask 077
age-keygen -o /media/recovery/recovery.agekey
age-keygen -y /media/recovery/recovery.agekey > keys/age/recovery.pub
```

Commit this secrets-management implementation and the recovery recipient
together, then push it. Do not rebuild a host until its
`secrets/<host>.json` exists.

On each of `jasper`, `punky`, and `blaze`, pull that commit and enter the pinned
tool environment:

```sh
cd /etc/nixos
git pull --ff-only
nix develop .#secrets
```

Export the live GPG key used by `pass` into the user runtime directory, then run
the migration. The script reads existing `/cold` values, creates this host's age
identity if necessary, and refuses to overwrite existing encrypted files or
different public keys.

```sh
umask 077
gpg --export-options backup --armor --export-secret-keys \
  > "$XDG_RUNTIME_DIR/pass-secret-key.asc"
doas env "PATH=$PATH" ./utils/migrate-secrets \
  "$XDG_RUNTIME_DIR/pass-secret-key.asc"
rm -- "$XDG_RUNTIME_DIR/pass-secret-key.asc"
```

Commit the generated `secrets/<host>.json` and `keys/` files. Before switching,
prove that both the host key and offline recovery key can decrypt the file:

```sh
SOPS_AGE_KEY_FILE=/cold/age/key.agekey sops decrypt \
  "secrets/$(hostname).json" >/dev/null
SOPS_AGE_KEY_FILE=/media/recovery/recovery.agekey sops decrypt \
  "secrets/$(hostname).json" >/dev/null
nixos-rebuild build --flake ".#$(hostname)"
doas nixos-rebuild switch --flake ".#$(hostname)"
```

Verify a fresh SSH login, a local password login after reboot, `pass`, and—on
Blaze—the phone VPN. Keep the old `/cold/secrets` tree until all three hosts and
the recovery key have been tested. Once migration is complete, delete
`utils/migrate-secrets` from the repository.

## Normal changes and rotation

Edit one encrypted host file with its local identity or the recovery identity:

```sh
export SOPS_AGE_KEY_FILE=/cold/age/key.agekey
export TMPDIR="$XDG_RUNTIME_DIR"
sops secrets/"$(hostname)".json
```

Commit, pull, and run `nixos-rebuild switch`. SOPS restarts the affected service
when the GPG export, WireGuard key, DuckDNS token, or Nix signing key changes.

SSH rotation needs an overlap: add the new public key to `users.nix`, deploy it
everywhere, update the relevant encrypted private key, test a fresh connection,
then remove the old public key. The phone's private SSH and WireGuard keys stay
on the phone; only their public files belong in `keys/`.

For GPG, rotate encryption subkeys under the existing primary identity. Export
the updated private key into each host's encrypted file, deploy it everywhere,
and only then re-encrypt the password store. Retain old encryption subkeys for
historical password-store revisions.

Changing Blaze's WireGuard private key also requires changing the server public
key in the phone configuration. Do that from LAN or console access.

Public SOPS ciphertext can be committed publicly, but publication is permanent:
someone who later obtains an age private key can decrypt every historical file
that was encrypted to it. Keep the repository private unless public availability
serves a purpose.
