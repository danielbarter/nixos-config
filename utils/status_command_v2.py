from abc import ABC, abstractmethod
import shutil
from subprocess import check_output, run
from glob import glob
from time import localtime, strftime
import json
import dbus

# connect to the system dbus
bus = dbus.SystemBus()

class BarSegment(ABC):
    """
    interface for a segment of the status bar
    """

    @staticmethod
    @abstractmethod
    def run() -> bool:
        """
        used to decide whether to display the bar segment, for
        example, checking if all the relevent commands or files are
        present
        """
        pass

    @staticmethod
    @abstractmethod
    def display() -> str:
        """
        method called when the bar segment is displayed
        """
        pass


class LoadAverage(BarSegment):
    @staticmethod
    def run():
        return True

    @staticmethod
    def display():
        output = open("/proc/loadavg", "r").readlines()
        output_split = output[0].split(" ")
        load_average_per_min =  output_split[0]
        load_average_per_five_min =  output_split[1]
        load_average_per_fifteen_min = output_split[2]
        return f"{load_average_per_min} {load_average_per_five_min} {load_average_per_fifteen_min}"


class Ram(BarSegment):
    @staticmethod
    def run():
        return True

    @staticmethod
    def display():
        output = open("/proc/meminfo","r").readlines()
        mem_total = int(output[0].split(" ")[-2])
        mem_avaliable = int(output[2].split(" ")[-2])
        mem_used = mem_total - mem_avaliable
        return f"💾{int(mem_used * 100 / mem_total)}%"


class Battery(BarSegment):
    @staticmethod
    def run():
        battery_capacity_path = glob("/sys/class/power_supply/BAT?/capacity")
        return len(battery_capacity_path) > 0

    @staticmethod
    def display():
        battery_capacity_path = glob("/sys/class/power_supply/BAT?/capacity")[0]
        battery_status_path = glob("/sys/class/power_supply/BAT?/status")[0]
        battery_capacity = open(battery_capacity_path, "r").read().rstrip()
        battery_status = open(battery_status_path, "r").read().rstrip()

        if battery_status == 'Charging':
            battery_icon = '⚡'
        else:
            battery_icon = '🔋'

        # if low battery, send notifaction
        if (battery_status != 'Charging' and int(battery_capacity) < 5):
            run(
                ['notify-send', '--urgency=critical', '--expire-time=2500', 'low battery!']
            )

        return battery_icon + battery_capacity + '%'


class Time(BarSegment):
    @staticmethod
    def run():
        return True

    @staticmethod
    def display():
        return  strftime('%H:%M %a %b %d', localtime())


class Network(BarSegment):
    @staticmethod
    def run():
        if shutil.which("ip") is None:
            return False
        else:
            return True

    @staticmethod
    def display():
        ip_addr_json = check_output(["ip", "-j", "addr"]).decode(encoding="ascii")
        ip_addr = json.loads(ip_addr_json)
        result = []
        for interface in ip_addr:
            if interface["operstate"] == "UP":
                interface_name = interface["ifname"]
                address = None
                subnet_prefix = None
                for addr in interface["addr_info"]:
                    if addr["family"] == "inet":
                        address = addr["local"]
                        subnet_prefix = addr["prefixlen"]

                if address is not None:
                    result.append(f"{interface_name} {address}/{subnet_prefix}")

        return "|".join(result)

def rssi_to_color(rssi):
    signal_strength_dBm = rssi / 100

    min_signal_power_dBm = -100
    max_signal_power_dBm = -20
    signal_power_range = max_signal_power_dBm - min_signal_power_dBm
    signal_strength_percent = 100 * ( signal_strength_dBm - min_signal_power_dBm ) / signal_power_range

    signal_strength_icon = '🔴'
    if signal_strength_percent > 33:
        signal_strength_icon = '🟠'
    if signal_strength_percent > 66:
        signal_strength_icon = '🟢'

    return signal_strength_icon


class Wireless(BarSegment):
    @staticmethod
    def run():
        if shutil.which("iwctl") is None:
            return False
        else:
            return True

    @staticmethod
    def display():
        result = []

        # get all dbus objects managed by iwd
        objects = dbus.Interface(
            bus.get_object("net.connman.iwd", "/"), "org.freedesktop.DBus.ObjectManager"
        ).GetManagedObjects()

        for path, interfaces in objects.items():

            if "net.connman.iwd.Station" in interfaces:
                station = dbus.Interface(bus.get_object("net.connman.iwd",path),"net.connman.iwd.Station")

                for network_path, rssi in station.GetOrderedNetworks():
                    network = objects[network_path]
                    ssid = network["net.connman.iwd.Network"]["Name"]
                    result.append(rssi_to_color(rssi) + " " + ssid)


        return "|".join(result)

class Bluetooth(BarSegment):
    @staticmethod
    def run():
        if shutil.which("bluetoothctl") is None:
            return False
        else:
            return True

    @staticmethod
    def display():
        result = []

        # get all dbus objects managed by bluez
        objects = dbus.Interface(
            bus.get_object("org.bluez", "/"), "org.freedesktop.DBus.ObjectManager"
        ).GetManagedObjects()

        for _, interfaces in objects.items():
            if "org.bluez.Device1" in interfaces:
                device = interfaces["org.bluez.Device1"]
                if device["Connected"]:
                    result.append(device["Alias"] + " " + device["Address"])


        return "🟦 " +  "|".join(result)

bar_segment_classes = [ LoadAverage, Ram, Network, Wireless, Bluetooth, Battery, Time ]
segment_seperator = "   "
to_display = []

for bar_segment_class in bar_segment_classes:
    if bar_segment_class.run():
        to_display.append(bar_segment_class.display())

print(segment_seperator.join(to_display))

