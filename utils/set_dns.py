"""
set_dns --ipv4 <address> --ipv6 <address>

Sets DNS servers for either NetworkManager (using nmcli/resolvconf) or
systemd-networkd/systemd-resolved (using a resolved.conf drop-in).
"""

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
from typing import Iterable, List


class CommandError(RuntimeError):
    """Raised when a shell command exits with a non-zero status."""


def run(cmd: List[str]) -> str:
    """Run a command and return stdout, raising on failure."""
    try:
        completed = subprocess.run(
            cmd,
            check=True,
            capture_output=True,
            text=True,
        )
    except subprocess.CalledProcessError as exc:
        output = exc.stderr.strip() or exc.stdout.strip()
        raise CommandError(f"{' '.join(cmd)} failed: {output}") from exc

    return completed.stdout.strip()


def require_root() -> None:
    if os.geteuid() != 0:
        sys.exit("set_dns must be run as root.")


def detect_manager() -> str:
    """Return which DNS manager to use."""
    if shutil.which("nmcli"):
        try:
            # nmcli exits non-zero if NetworkManager is not running.
            run(["nmcli", "-t", "-f", "RUNNING", "general"])
            return "networkmanager"
        except CommandError:
            pass

    if shutil.which("resolvectl"):
        return "systemd-resolved"

    sys.exit("Could not find NetworkManager (nmcli) or systemd-resolved (resolvectl).")


def apply_networkmanager(ipv4: str | None, ipv6: str | None) -> None:
    active = run(["nmcli", "-t", "-f", "NAME", "connection", "show", "--active"])
    connections = [name for name in active.splitlines() if name]
    if not connections:
        raise SystemExit("No active NetworkManager connections found.")

    for connection in connections:
        modifications: List[str] = []
        if ipv4:
            modifications += [
                "ipv4.ignore-auto-dns",
                "yes",
                "ipv4.dns",
                ipv4,
            ]
        if ipv6:
            modifications += [
                "ipv6.ignore-auto-dns",
                "yes",
                "ipv6.dns",
                ipv6,
            ]

        if not modifications:
            continue

        run(["nmcli", "connection", "modify", connection, *modifications])
        run(["nmcli", "connection", "up", connection])


def write_resolved_dropin(dns_servers: Iterable[str]) -> None:
    base_dir = "/etc/systemd/resolved.conf.d"
    os.makedirs(base_dir, exist_ok=True)
    dropin = os.path.join(base_dir, "10-set-dns.conf")
    dns_line = " ".join(dns_servers)

    content = "[Resolve]\nDNS=" + dns_line + "\nFallbackDNS=\n"
    with open(dropin, "w", encoding="ascii") as handle:
        handle.write(content)


def apply_systemd_resolved(ipv4: str | None, ipv6: str | None) -> None:
    dns_servers = [addr for addr in (ipv4, ipv6) if addr]
    if not dns_servers:
        raise SystemExit("No DNS servers provided.")

    write_resolved_dropin(dns_servers)
    try:
        run(["systemctl", "reload-or-restart", "systemd-resolved.service"])
    except CommandError:
        # Fallback to restart if reload is unsupported.
        run(["systemctl", "restart", "systemd-resolved.service"])


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Set IPv4/IPv6 DNS servers.")
    parser.add_argument("--ipv4", help="IPv4 DNS server address", default=None)
    parser.add_argument("--ipv6", help="IPv6 DNS server address", default=None)
    args = parser.parse_args()

    if not args.ipv4 and not args.ipv6:
        parser.error("at least one of --ipv4 or --ipv6 must be provided")

    return args


def main() -> None:
    args = parse_args()
    require_root()
    manager = detect_manager()

    if manager == "networkmanager":
        apply_networkmanager(args.ipv4, args.ipv6)
        print("DNS updated via NetworkManager for active connections.")
    else:
        apply_systemd_resolved(args.ipv4, args.ipv6)
        print("DNS updated for systemd-resolved.")


if __name__ == "__main__":
    main()
