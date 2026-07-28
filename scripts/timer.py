import time

class Timer:

    def __init__(self):
        self.start = time.time()

    def stop(self):

        end = time.time()

        return round(end-self.start,2)