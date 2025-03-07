# NixOS system configuration


### Secrets

```
# gpg keys are imported as follows
$ gpg --import /etc/nixos/secrets/gpg/privkey.asc /etc/nixos/public/gpg/public.asc

# gpg keys are generated as follows:
$ gpg --full-generate-key
$ gpg --output public.asc --armor --export <fingerprint>
$ gpg --output privkey.asc --armor --export-secret-key <fingerprint>
$ ssh-keygen
```
