from abc import ABC, abstractmethod
import shutil
from subprocess import check_output, run


class BarSegment(ABC):
    """
    interface for a segment of the status bar
    """

    @staticmethod
    @abstractmethod
    def run() -> bool:
        """
        method to decide if BarSegment should be used. For example, if we are not
        on a laptop, we don't need to try and get battery stats
        """
        pass

    @abstractmethod
    def __init__(self):
        """
        on object instantiation, external processes are spawned and outputs are collected
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


bar_segment_classes = [ LoadAverage, Ram ]
to_display = []

for bar_segment_class in bar_segment_classes:
    if bar_segment_class.run():
        bar_segment = bar_segment_class()
        to_display.append(bar_segment.display())

print("   ".join(to_display))

