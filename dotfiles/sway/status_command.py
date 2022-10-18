import re

from os.path import isfile
from time import localtime, strftime
from subprocess import check_output, run
from glob import glob

to_display = []

def get_load_average():
    load_average_output = check_output(['uptime']).decode(encoding='ascii').split(' ')

    load_average_per_min =  load_average_output[-3][0:-1]
    load_average_per_five_min =  load_average_output[-2][0:-1]
    load_average_per_fifteen_min = load_average_output[-1][0:-1]

    to_display.append('{} {} {}'.format(
        load_average_per_min,
        load_average_per_five_min,
        load_average_per_fifteen_min))

get_load_average()


def get_ram_stats():
    free_output = check_output(['free', '-m']).decode(encoding='ascii').split('\n')
    mem_line = [s for s in free_output[1].split(' ') if s != '']
    total = mem_line[1]
    used = mem_line[2]
    ram_bar = '💾' + str(int(int(used) * 100 / int(total))) + '%'
    to_display.append(ram_bar)

get_ram_stats()



def get_wireless_interface_names():
    """ Extract wireless device names from /proc/net/wireless.

        Returns empty list if no devices are present.
    """
    device_regex = re.compile('[a-z0-9]*:')
    ifnames = []

    fp = open('/proc/net/wireless', 'r')
    for line in fp:
        maybe_Match = device_regex.search(line)
        if maybe_Match:
            ifnames.append(maybe_Match.group(0)[:-1])
    return ifnames

def get_ssid_and_link_quality(interface):
    wifi_display = []

    iwlink_output = check_output(['iw','dev',interface,'link']).decode(encoding='ascii')
    ipaddr_output = check_output(['ip','addr','show','dev',interface]).decode(encoding='ascii')

    link_quality_regex = re.compile('signal: .*dBm')
    maybe_link_quality_match = link_quality_regex.search(iwlink_output)
    if maybe_link_quality_match:
        signal_strength_dBm = int(maybe_link_quality_match.group(0)[8:-4])

        min_signal_power_dBm = -100
        max_signal_power_dBm = -20
        signal_power_range = max_signal_power_dBm - min_signal_power_dBm
        signal_strength_percent = 100 * ( signal_strength_dBm - min_signal_power_dBm ) / signal_power_range

        signal_strength_icon = '🔴'
        if signal_strength_percent > 33:
            signal_strength_icon = '🟠'
        if signal_strength_percent > 66:
            signal_strength_icon = '🟢'

        wifi_display.append(signal_strength_icon)

    ssid_regex = re.compile('SSID: .*')
    maybe_ssid_match = ssid_regex.search(iwlink_output)
    if maybe_ssid_match:
        wifi_display.append(maybe_ssid_match.group(0)[6:])

    local_ipv4_regex = re.compile('inet \d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/\d{1,2}')
    maybe_ipv4_match = local_ipv4_regex.search(ipaddr_output)
    if maybe_ipv4_match:
        wifi_display.append(maybe_ipv4_match.group(0)[5:])

    to_display.append(' '.join(wifi_display))

wireless_interfaces = get_wireless_interface_names()

if wireless_interfaces:
    # hopefully there aren't two active wireless interfaces....
    first_interface = wireless_interfaces[0]
    get_ssid_and_link_quality(first_interface)




# sometimes these sym links are named differently
try:
    battery_capacity_path = glob('/sys/class/power_supply/BAT?/capacity')[0]
    battery_status_path = glob('/sys/class/power_supply/BAT?/status')[0]
except IndexError:
    battery_capacity_path = ""

if isfile(battery_capacity_path):
    battery_capacity_file = open(battery_capacity_path, 'r')
    battery_capacity = battery_capacity_file.read().rstrip()

    battery_status_file = open(battery_status_path, 'r')
    battery_status = battery_status_file.read().rstrip()
    if battery_status == 'Charging':
        battery_icon = '⚡'
    else:
        battery_icon = '🔋'

    if (battery_status != 'Charging' and int(battery_capacity) < 5):
        run(
            ['swaynag', '--message', 'low battery!', '-f', 'SourceCodePro Regular 11'])

    battery_bar = battery_icon + battery_capacity + '%'
    to_display.append(battery_bar)

time_bar = strftime('%H:%M %a %b %d', localtime())
to_display.append(time_bar)


print('   '.join(to_display))
