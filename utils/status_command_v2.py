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
        used to decide whether to instantiate the bar segment, for example, checking if
        all the relevent commands are present in the path
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
    def run() -> bool:
        uptime_path = shutil.which("uptime")
        if uptime_path is None:
            return False
        else:
            return True

    def __init__(self):
        self.output = check_output(["uptime"]).decode(encoding="ascii")

    def display(self):
        output_split = self.output.split(" ")
        load_average_per_min =  output_split[-3][0:-1]
        load_average_per_five_min =  output_split[-2][0:-1]
        load_average_per_fifteen_min = output_split[-1][0:-1]
        return f"{load_average_per_min} {load_average_per_five_min} {load_average_per_fifteen_min}"


bar_segment_classes = [ LoadAverage ]
to_display = []

for bar_segment_class in bar_segment_classes:
    if bar_segment_class.run():
        bar_segment = bar_segment_class()
        to_display.append(bar_segment.display())


print("   ".join(to_display))

