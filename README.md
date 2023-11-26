# NixOS system configuration


### Secrets

```
# Secrets are stored (not in VC!) as follows:
# /etc/nixos/secrets/
# ├── binary-cache
# │   ├── cache-priv-key.pem
# ├── gpg
# │   ├── privkey.asc
# └── ssh
#     ├── id_rsa

# make sure all the leaves have permissions 600, with appropriate user and group
# see set_permissions.sh

# corresponding public keys are stored as follows:
# /etc/nixos/public/
# ├── binary-cache
# │   ├── cache-pub-key.pem
# ├── gpg
# │   ├── public.asc
# └── ssh
#     ├── id_rsa.pub

# gpg keys are imported as follows
$ gpg --import /etc/nixos/secrets/gpg/privkey.asc /etc/nixos/public/gpg/public.asc

# secrets are generated as follows:
$ gpg --full-generate-key
$ gpg --output public.asc --armor --export <email>
$ gpg --output privkey.asc --armor --export-secret-key <email>
$ ssh-keygen
```
