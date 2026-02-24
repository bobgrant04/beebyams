# vibethinker_debugger.py

import sys

class Debugger:
    def __init__(self, enable=True):
        self.enabled = enable

    def log(self, message):
        if self.enabled:
            print(f"DEBUG: {message}")

def main():
    debug_mode = '--debug' in sys.argv
    debugger = Debugger(debug_mode)

    # Example usage
    debugger.log("This is a debug message.")

if __name__ == "__main__":
    main()