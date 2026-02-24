# vibethinker_debug.py

import sys
import os

class Debugger:
    def __init__(self, enabled=True):
        self.enabled = enabled

    def debug_print(self, message):
        if self.enabled:
            print(message)

if __name__ == "__main__":
    # Example usage
    db = Debugger()
    db.debug_print("This is a debug message.")
  