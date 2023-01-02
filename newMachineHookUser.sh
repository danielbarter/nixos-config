# import gpg keys
gpg --import /etc/nixos/secrets/gpg/privkey.asc /etc/nixos/secrets/gpg/public.asc

# grab passwords or create a new password repo
git clone git@github.com:danielbarter/password_store.git /home/danielbarter/.password-store
