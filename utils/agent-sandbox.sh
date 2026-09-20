#!@bash@
# shellcheck shell=bash
set -euo pipefail

# Hide SOPS paths, the normal GPG/SSH homes, and authentication sockets.
runtime=${XDG_RUNTIME_DIR:-/run/user/$(id -u)}
paths=(
  /cold /run/secrets /run/secrets.d
  /run/secrets-for-users /run/secrets-for-users.d
  "$HOME/.gnupg" "$HOME/.ssh" "$HOME/.config/sops"
  "$runtime/gnupg"
  "$runtime/bus" "$runtime/systemd/private" /run/dbus/system_bus_socket
)
if [[ -n ${SSH_AUTH_SOCK:-} ]]; then paths+=("$SSH_AUTH_SOCK"); fi
if [[ -n ${GNUPGHOME:-} ]]; then paths+=("$GNUPGHOME"); fi
inaccessible=
for path in "${paths[@]}"; do
  # systemd parses quoted path lists and expands % specifiers.
  path=${path//\\/\\\\}
  path=${path//\"/\\\"}
  path=${path//%/%%}
  inaccessible+=" \"-$path\""
done

exec @systemd_run@ --user --pty --wait --collect \
  --working-directory="$PWD" \
  --property="InaccessiblePaths=$inaccessible" \
  --property=NoNewPrivileges=yes \
  --property=RestrictSUIDSGID=yes \
  --setenv=SSH_AUTH_SOCK= --setenv=GPG_AGENT_INFO= \
  --setenv=DBUS_SESSION_BUS_ADDRESS= \
  -- @binary@ --dangerously-bypass-approvals-and-sandbox "$@"
