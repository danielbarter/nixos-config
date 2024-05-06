from abc import ABC, abstractmethod
import shutil
from subprocess import check_output, run
from glob import glob
from time import localtime, strftime

class BarSegment(ABC):
    """
    interface for a segment of the status bar
    """

    @staticmethod
    @abstractmethod
    def run() -> bool:
        """
        used to decide whether to instantiate the bar segment, for
        example, checking if all the relevent commands are present in
        the path, or if we are not on a laptop, we don't need to try
        and get battery stats
        """
        pass

    @abstractmethod
    def __init__(self):
        """
        on object instantiation, we read from the proc or sys
        filesystem, or spawn an external process which does this
        """
        pass

    @abstractmethod
    def display(self) -> str:
        """
        method called when the bar segment is displayed
        """
        pass


class LoadAverage(BarSegment):
    @staticmethod
    def run():
        return True

    def __init__(self):
        self.output = open("/proc/loadavg", "r").readlines()

    def display(self):
        output_split = self.output[0].split(" ")
        load_average_per_min =  output_split[0]
        load_average_per_five_min =  output_split[1]
        load_average_per_fifteen_min = output_split[2]
        return f"{load_average_per_min} {load_average_per_five_min} {load_average_per_fifteen_min}"


class Ram(BarSegment):
    @staticmethod
    def run():
        return True

    def __init__(self):
        self.output = open("/proc/meminfo","r").readlines()

    def display(self):
        mem_total = int(self.output[0].split(" ")[-2])
        mem_avaliable = int(self.output[2].split(" ")[-2])
        mem_used = mem_total - mem_avaliable
        return f"💾{int(mem_used * 100 / mem_total)}%"


class Battery(BarSegment):
    @staticmethod
    def run():
        battery_capacity_path = glob("/sys/class/power_supply/BAT?/capacity")
        return len(battery_capacity_path) > 0

    def __init__(self):
        battery_capacity_path = glob("/sys/class/power_supply/BAT?/capacity")[0]
        battery_status_path = glob("/sys/class/power_supply/BAT?/status")[0]
        self.battery_capacity = open(battery_capacity_path, "r").read().rstrip()
        self.battery_status = open(battery_status_path, "r").read().rstrip()

    def display(self):
        if self.battery_status == 'Charging':
            battery_icon = '⚡'
        else:
            battery_icon = '🔋'

        # if low battery, send notifaction
        if (self.battery_status != 'Charging' and int(self.battery_capacity) < 5):
            run(
                ['notify-send', '--urgency=critical', '--expire-time=2500', 'low battery!']
            )

        return battery_icon + self.battery_capacity + '%'


class Time(BarSegment):
    @staticmethod
    def run():
        return True

    def __init__(self):
        pass

    def display(self):
        return  strftime('%H:%M %a %b %d', localtime())

bar_segment_classes = [ LoadAverage, Ram, Battery, Time ]
segment_seperator = "   "
to_display = []

for bar_segment_class in bar_segment_classes:
    if bar_segment_class.run():
        bar_segment = bar_segment_class()
        to_display.append(bar_segment.display())

print(segment_seperator.join(to_display))

