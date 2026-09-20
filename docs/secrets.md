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
Nix signing key used to verify cache paths. Their `danielbarter` and root
accounts have empty passwords for local login. Consoles automatically log in
as `danielbarter`, as does the COSMIC desktop on graphical images. SSH uses
public-key authentication. Images do not receive a private SSH client key,
Nix signing private key, or `pass` key.

## Normal changes and rotation

On the host whose secrets you want to edit, enter the pinned tool environment:

```sh
cd /etc/nixos
nix develop .#secrets
```

Edit one encrypted host file using its local identity:

```sh
doas env "PATH=$PATH" "TMPDIR=$XDG_RUNTIME_DIR" \
  SOPS_AGE_KEY_FILE=/cold/age/key.agekey sops "secrets/$(hostname).json"
```

Verify decryption, then build and activate the configuration:

```sh
doas env "PATH=$PATH" SOPS_AGE_KEY_FILE=/cold/age/key.agekey sops decrypt \
  "secrets/$(hostname).json" >/dev/null
nixos-rebuild build --flake ".#$(hostname)"
doas nixos-rebuild switch --flake ".#$(hostname)"
```

Commit and push the encrypted changes. SOPS restarts the affected service when
the GPG export, WireGuard key, DuckDNS token, or Nix signing key changes.

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
