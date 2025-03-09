#!/usr/bin/env python3

import requests
import os
import time
import re
import argparse

def is_valid_ipv4(address):
    ipv4_pattern = r"^(\d{1,3}\.){3}\d{1,3}$"
    if not re.match(ipv4_pattern, address):
        raise Exception(
            f"""
            invalid ip address: {address}
            """
        )

parser = argparse.ArgumentParser(description="update duckdns")
parser.add_argument("--token_file", type=str, required=True)
parser.add_argument("--domain", type=str, required=True)
args = parser.parse_args()


cached_ip_file_path = '/tmp/cached_ip'

# touch cached_ip file if it doesn't exist
if not os.path.exists(cached_ip_file_path):
    with open(cached_ip_file_path,'w') as f:
        f.write("")

with open(cached_ip_file_path,'r') as f:
    cached_ip = f.read()

current_ip_response = requests.get("http://ipv4.wtfismyip.com/text")
current_ip: str = current_ip_response.text[:-1]
is_valid_ipv4(current_ip)


if current_ip != cached_ip:
    print(f"ip change: current = {current_ip}, cached = {cached_ip if len(cached_ip) > 0 else "_"}") 
    with open(cached_ip_file_path,'w') as f:
        f.write(current_ip)

    with open(args.token_file,'r') as f:
        token = f.read()[:-1]
    update_ip_url = f"https://www.duckdns.org/update?domains={args.domain}&token={token}&ip={current_ip}"
    update_ip_response = requests.get(update_ip_url)
    status = update_ip_response.text
    if status == "OK":
        print("ip update successful")
    else:        
        print("ip update failed")
    

else:
    print(f"no ip change: ip = {current_ip}") 

