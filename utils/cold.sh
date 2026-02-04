# Generate a full set of fresh keys under a target directory.
# Requires: gpg, ssh-keygen, wg, nix (nix-key).
# Notes:
# - GPG generation is interactive (strong defaults via agent + modern algorithms).
# - SSH uses Ed25519 (strong, modern).
# - WireGuard uses Curve25519 via wg genkey/pubkey.
# - Nix signing key uses nix-key generate-secret (Ed25519).

gen_cold_sec() {
  set -uo pipefail

  local root="${1:-}"
  if [[ -z "${root}" ]]; then
    echo "usage: gen_keys <target-dir>" >&2
    return 2
  fi

  local secrets_dir="${root%/}/secrets"
  local public_dir="${root%/}/public"

  # Create directory structure
  install -d -m 0700 \
    "${secrets_dir}/gpg" \
    "${secrets_dir}/nix" \
    "${secrets_dir}/ssh" \
    "${secrets_dir}/wireguard" \
    "${public_dir}/gpg" \
    "${public_dir}/nix" \
    "${public_dir}/ssh" \
    "${public_dir}/wireguard"

  # ---- GPG (ed25519/cv25519, exports armored keys) ----
  # Use an isolated GNUPGHOME under secrets, so we don't touch your normal keyring.
  local gnupghome="${secrets_dir}/gpg/.gnupg"
  install -d -m 0700 "${gnupghome}"
  chmod 0700 "${gnupghome}"

  echo "Generating GPG key (interactive). Choose:"
  echo "  - Key type: ECC (sign + encrypt) / default modern ECC"
  echo "  - Curve: ed25519 for signing + cv25519 for encryption (if prompted)"
  echo "  - Expiration: set one (recommended)"
  echo "  - Passphrase: strong passphrase (recommended)"
  GNUPGHOME="${gnupghome}" gpg --full-generate-key

  # Pick the most recently created secret key in this isolated keyring.
  local gpg_fpr
  gpg_fpr="$(GNUPGHOME="${gnupghome}" gpg --list-secret-keys --with-colons \
    | awk -F: '$1=="fpr"{print $10}' | tail -n 1)"

  if [[ -z "${gpg_fpr}" ]]; then
    echo "Failed to determine newly generated GPG key fingerprint." >&2
    return 1
  fi

  GNUPGHOME="${gnupghome}" gpg --armor --export-secret-keys "${gpg_fpr}" > "${secrets_dir}/gpg/privkey.asc"
  GNUPGHOME="${gnupghome}" gpg --armor --export "${gpg_fpr}" > "${public_dir}/gpg/public.asc"

  # ---- SSH (Ed25519) ----
  # (Your tree says id_rsa/id_rsa.pub, but Ed25519 is stronger than RSA; we generate id_ed25519
  # and also provide compatibility symlinks named id_rsa/id_rsa.pub.)
  ssh-keygen -t ed25519 -a 100 -f "${secrets_dir}/ssh/id_ed25519"
  cp -f "${secrets_dir}/ssh/id_ed25519.pub" "${public_dir}/ssh/id_ed25519.pub"

  ln -sfn "id_ed25519"     "${secrets_dir}/ssh/id_rsa"
  ln -sfn "id_ed25519.pub" "${public_dir}/ssh/id_rsa.pub"

  # ---- WireGuard ----
  # Generate two independent keypairs: blaze and punky
  for name in blaze punky; do
    umask 077
    wg genkey | tee "${secrets_dir}/wireguard/${name}" | wg pubkey > "${public_dir}/wireguard/${name}"
  done

  # ---- Nix substituter signing key ----
  # Produces Ed25519-based signing keys for binary cache/substituters.
  if command -v nix >/dev/null 2>&1; then
    nix key generate-secret --key-name "punky_cache" > "${secrets_dir}/nix/private-key"
    nix key convert-secret-to-public < "${secrets_dir}/nix/private-key" > "${public_dir}/nix/public-key"
  else
    echo "nix-key not found. Install Nix that provides nix-key, then rerun Nix section." >&2
  fi

  echo "Done. Run: set_key_perms '${root%/}'"
}

# Set permissions and ownership for the created tree.
# - secrets: 0700/0600
# - public:  0755/0644
# - WireGuard secret keys: owner root, group systemd-network, mode 0640
set_cold_perms() {
  set -uo pipefail

  local root="${1:-}"
  if [[ -z "${root}" ]]; then
    echo "usage: set_key_perms <target-dir>" >&2
    return 2
  fi

  local secrets_dir="${root%/}/secrets"
  local public_dir="${root%/}/public"

  if [[ ! -d "${secrets_dir}" || ! -d "${public_dir}" ]]; then
    echo "Expected '${secrets_dir}' and '${public_dir}' to exist." >&2
    return 2
  fi

  # Base directory perms
  sudo find "${secrets_dir}" -type d -exec chmod 0700 {} +
  sudo find "${public_dir}"  -type d -exec chmod 0755 {} +

  # Secret files: 0600 by default
  sudo find "${secrets_dir}" -type f -exec chmod 0600 {} +

  # Public files: 0644
  sudo find "${public_dir}" -type f -exec chmod 0644 {} +

  # WireGuard secret keys: root:systemd-network 0640
  # (Group must exist; on most systemd systems it does.)
  if getent group systemd-network >/dev/null 2>&1; then
    sudo chown root:systemd-network "${secrets_dir}/wireguard/"{blaze,punky} 2>/dev/null || true
    sudo chmod 0640 "${secrets_dir}/wireguard/"{blaze,punky} 2>/dev/null || true
  else
    echo "Warning: group 'systemd-network' not found; skipping wireguard group ownership." >&2
  fi

  # GPG home strict perms if present
  if [[ -d "${secrets_dir}/gpg/.gnupg" ]]; then
    sudo chmod 0700 "${secrets_dir}/gpg/.gnupg"
    sudo find "${secrets_dir}/gpg/.gnupg" -type f -exec chmod 0600 {} +
  fi
}


# Format a block device with GPT, create 1 partition labeled "cold", and make ext4
# Usage: format_cold /dev/sdX   (or /dev/nvme0n1)
format_cold() {
  set -euo pipefail

  if [[ $# -ne 1 ]]; then
    echo "Usage: format_cold /dev/<disk>" >&2
    return 2
  fi

  local disk="$1"

  if [[ ! -b "$disk" ]]; then
    echo "Error: '$disk' is not a block device." >&2
    return 2
  fi

  # Refuse obvious partition paths (expects whole-disk like /dev/sdb, /dev/nvme0n1)
  if [[ "$disk" =~ [0-9]$ ]] && [[ ! "$disk" =~ nvme[0-9]n[0-9]$ ]]; then
    echo "Error: '$disk' looks like a partition; pass the whole disk (e.g. /dev/sdb)." >&2
    return 2
  fi

  echo "About to DESTROY all data on: $disk" >&2
  echo "Current layout:" >&2
  lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,MOUNTPOINT "$disk" >&2 || true

  # If anything is mounted from this disk, unmount it.
  local mps
  mps="$(lsblk -nr -o MOUNTPOINT "$disk" | awk 'NF{print}')"
  if [[ -n "${mps}" ]]; then
    echo "Unmounting mounted filesystems on $disk..." >&2
    while read -r mp; do
      sudo umount "$mp"
    done <<< "${mps}"
  fi

  # Zap signatures (best-effort) to avoid old superblocks confusing tools.
  sudo wipefs -a "$disk"

  # Create GPT and one primary partition spanning the disk.
  sudo parted -s "$disk" mklabel gpt
  sudo parted -s "$disk" mkpart primary ext4 1MiB 100%

  # Ensure kernel sees new partition table.
  sudo partprobe "$disk"
  sudo udevadm settle

  # Determine created partition path.
  local part
  if [[ "$disk" =~ nvme[0-9]n[0-9]$ ]]; then
    part="${disk}p1"
  else
    part="${disk}1"
  fi

  if [[ ! -b "$part" ]]; then
    echo "Error: partition device '$part' not found." >&2
    return 1
  fi

  # Make ext4 with filesystem label "cold"
  sudo mkfs.ext4 -F -L cold "$part"

  echo "Done." >&2
  echo "Disk:  $disk" >&2
  echo "Part:  $part" >&2
  echo "Label: cold" >&2
}
