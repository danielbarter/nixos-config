#!/usr/bin/env python3

import requests
import os
import argparse
from subprocess import check_output
import json


parser = argparse.ArgumentParser(description="update duckdns")
parser.add_argument("--token_file", type=str, required=True)
parser.add_argument("--domain", type=str, required=True)
parser.add_argument("--wan_interface", type=str, required=True)
args = parser.parse_args()


cached_ip_file_path = '/tmp/cached_ip'

# touch cached_ip file if it doesn't exist
if not os.path.exists(cached_ip_file_path):
    with open(cached_ip_file_path,'w') as f:
        f.write("")

with open(cached_ip_file_path,'r') as f:
    cached_ip = f.read()


current_ip = None

ip_addr_json = check_output(["ip", "-j", "addr"]).decode(encoding="ascii")
ip_addr = json.loads(ip_addr_json)
for interface in ip_addr:
    if interface["ifname"] == args.wan_interface:
        for addr in interface["addr_info"]:
            if addr["family"] == "inet":
                current_ip = addr["local"]

if current_ip is None:
    raise Exception(
        "unable to extract WAN IP address from ip addr"
    )

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

