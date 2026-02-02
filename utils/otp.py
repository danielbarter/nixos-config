#! /usr/bin/env nix-shell
#! nix-shell -i python3 -p python3 python3Packages.pyotp
import sys
import time
import urllib.parse
import pyotp

def main():
    url = sys.stdin.read().strip()
    if not url:
        sys.exit("No otpauth URL provided on stdin")

    try:
        totp = pyotp.parse_uri(url)
    except Exception as e:
        sys.exit(f"Invalid otpauth URL: {e}")

    # Print current OTP code
    print(totp.now())

if __name__ == "__main__":
    main()
