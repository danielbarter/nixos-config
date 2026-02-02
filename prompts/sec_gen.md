Write me a bash function gen_cold, which generates fresh private/public keys using standard tools into a folder passed in as an argument with the following subfolders:

secrets
├── gpg
│   └── privkey.asc
├── nix
│   └── private-key
├── ssh
│   └── id_rsa
└── wireguard
    ├── blaze
    └── punky


public
├── gpg
│   └── public.asc
├── nix
│   └── public-key
├── ssh
│   ├── id_rsa.pub
└── wireguard
    ├── blaze
    └── punky


the nix private-key/public-key pair is a nix signing key for substituters. It is fine if the function requires human interaction. Please use strong encryption protocols.

Write a second function set_cold_perms which sets the permissions correctly. Wireguard secrets should have owner and group systemd-network
