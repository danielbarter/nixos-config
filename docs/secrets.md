# Secrets

Each physical host has one age identity at `/cold/age/key.agekey`. Its private
key never enters Git. The corresponding public recipient, ordinary public keys,
and SOPS-encrypted host secrets are committed to this repository. Each host's
file is encrypted only to its own age key. Keep a backup of that private key;
it is needed to recover the secrets if the `/cold` drive fails.

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

Commit and push this secrets-management implementation. The migration script
creates the age key on each host's existing `/cold` drive; no separate recovery
key is required. Do not rebuild a host until its `secrets/<host>.json` exists
and the generated public keys and encrypted file are tracked in Git.

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
verify that the host key can decrypt the file (the key is readable only by root):

```sh
doas env "PATH=$PATH" SOPS_AGE_KEY_FILE=/cold/age/key.agekey sops decrypt \
  "secrets/$(hostname).json" >/dev/null
nixos-rebuild build --flake ".#$(hostname)"
doas nixos-rebuild switch --flake ".#$(hostname)"
```

Verify a fresh SSH login, a local password login after reboot, `pass`, and—on
Blaze—the phone VPN. Keep the old `/cold/secrets` tree until all three hosts
have been tested. Once migration is complete, remove the old `/cold/secrets`
and `/cold/public` trees, leaving `/cold/age/key.agekey`, and delete
`utils/migrate-secrets` from the repository.

## Normal changes and rotation

Edit one encrypted host file using its local identity:

```sh
doas env "PATH=$PATH" "TMPDIR=$XDG_RUNTIME_DIR" \
  SOPS_AGE_KEY_FILE=/cold/age/key.agekey sops "secrets/$(hostname).json"
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
