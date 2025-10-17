#!/usr/bin/env python3
"""
Python equivalent of the BBC Micro MAGIC program for intelligently guessing
file types and determining appropriate load/execution addresses.

This program analyzes the first 256 bytes of a file to identify:
- File type (BASIC, machine code, screens, etc.)
- Appropriate load address
- Appropriate execution address
- Screen modes for graphics files
"""

import struct
import sys
from typing import List, Tuple, Optional, Dict, Any


class MagicEntry:
    """Represents a single magic data entry from MAGIC_SOURCE.ASM"""

    def __init__(self, entry_type: int, data: List[int], exec_addr: int, load_addr: int, description: str):
        self.entry_type = entry_type
        self.data = data  # List of integers (bytes)
        self.exec_addr = exec_addr
        self.load_addr = load_addr
        self.description = description


class MagicAnalyzer:
    """Python equivalent of the BBC Micro MAGIC program"""

    def __init__(self):
        self.raw_data = [0] * 256  # First page of file data
        self.file_size = 0
        self.current_load = 0
        self.current_exec = 0
        self.magic_entries = []
        self.load_magic_data()

    def load_magic_data(self):
        """Load magic data tables by parsing MAGIC_SOURCE.ASM file"""
        try:
            self.parse_magic_source_file("MAGIC_SOURCE.ASM")
        except Exception as e:
            print(f"Warning: Could not load MAGIC_SOURCE.ASM: {e}")
            print("Using fallback hardcoded magic data...")
            self.load_fallback_magic_data()

    def parse_magic_source_file(self, filename: str):
        """Parse the MAGIC_SOURCE.ASM file to extract magic data entries"""
        with open(filename, 'r') as f:
            lines = f.readlines()

        # Find lines that start with EQUS
        in_magic_section = False

        for line in lines:
            line = line.strip()
            if not line or line.startswith('\\'):
                continue

            if ".MagicData" in line:
                in_magic_section = True
                continue

            if not in_magic_section:
                continue

            if line.startswith('EQUS'):
                # Parse the EQUS line carefully
                # Format: EQUS type,data,exec,load,ident,"description",13
                self.parse_equs_line(line)

            # Check for end marker
            if "EQUS 0" in line:
                break

        # Add end marker
        self.magic_entries.append(MagicEntry(0, [], 0x0000, 0x00, ""))

    def parse_equs_line(self, line: str):
        """Parse a single EQUS line from MAGIC_SOURCE.ASM"""
        import re

        # Handle the end marker
        if line.strip() == 'EQUS 0':
            return

        # Pattern to match EQUS lines with quoted descriptions
        # EQUS type,data,exec_low,exec_high,load_low,load_high,"description",13
        # Handle the case where some entries might have different formats
        pattern = r'EQUS\s+([^,]+),\s*(.+?),\s*([^,]+),\s*([^,]+),\s*([^,]*?),\s*([^,]*?),\s*"([^"]+)"(?:,13)?'

        # Also try pattern for &FF entries: EQUS &FF,&FD,&7F,0,0,"Showpic #1",13
        ff_pattern = r'EQUS\s+([^,]+),\s*([^,]+),\s*([^,]+),\s*([^,]*?),\s*([^,]*?),\s*"([^"]+)"(?:,13)?'

        # Special pattern for Magic10 entries: EQUS 10,load,offset_from_end,exec,load,ident
        magic10_pattern = r'EQUS\s+10,\s*([^,]+),\s*([^,]+),\s*([^,]+),\s*([^,]*?),\s*([^,]*?),\s*([^,]*?),\s*([^,]*?),\s*([^,]*?),\s*"([^"]+)"(?:,13)?'
        match = re.match(pattern, line.strip())

        if match:
            try:
                entry_type = self.parse_hex_value(match.group(1))
                data_str = match.group(2)

                # Parse addresses in little-endian format as stored in MAGIC_SOURCE.ASM
                # For "TYB music samples #4": &F9,&7F,0,&11
                # Group 3: &F9 (exec low), Group 4: &7F (exec high)
                # Group 5: 0 (load low), Group 6: &11 (load high)
                exec_low = self.parse_hex_value(match.group(3))   # &F9
                exec_high = self.parse_hex_value(match.group(4)) # &7F
                exec_addr = (exec_high << 8) | exec_low          # 0x7FF9

                # Handle load address - some entries have different formats
                load_group5 = match.group(5) if match.group(5) else "0"
                load_group6 = match.group(6) if match.group(6) else "0"

                # Check if group 5 and 6 are both hex values (addresses) or if group 5 is load address
                if load_group6 and all(c in '0123456789ABCDEFabcdef&' for c in load_group6):
                    # Two-byte load address format: load_low, load_high
                    load_low = self.parse_hex_value(load_group5)
                    load_high = self.parse_hex_value(load_group6)
                    load_addr = (load_high << 8) | load_low
                else:
                    # Single-byte load address format: just load_low
                    load_addr = self.parse_hex_value(load_group5)

                description = match.group(7)

                # Parse data section
                data_values = self.parse_data_section(data_str)

                # Create the magic entry
                magic_entry = MagicEntry(entry_type, data_values, exec_addr, load_addr, description)
                self.magic_entries.append(magic_entry)

            except Exception as e:
                print(f"Warning: Could not parse EQUS line '{line}': {e}")
        else:
            # Try the special pattern for Magic10 entries
            magic10_match = re.match(magic10_pattern, line.strip())
            if magic10_match:
                try:
                    entry_type = 10
                    load_addr = self.parse_hex_value(magic10_match.group(1))  # load address
                    offset_from_end_low = self.parse_hex_value(magic10_match.group(2))  # offset from end (low byte)
                    offset_from_end_high = self.parse_hex_value(magic10_match.group(3))  # offset from end (high byte)
                    exec_low = self.parse_hex_value(magic10_match.group(4))  # exec address (low byte)
                    exec_high = self.parse_hex_value(magic10_match.group(5))  # exec address (high byte)
                    load_low = self.parse_hex_value(magic10_match.group(6))  # load address (low byte)
                    load_high = self.parse_hex_value(magic10_match.group(7))  # load address (high byte)
                    description = magic10_match.group(9)  # description

                    # Create data array for Magic10: [load_addr, offset_from_end_low, offset_from_end_high, exec_low, exec_high, load_low, load_high]
                    data_values = [load_addr, offset_from_end_low, offset_from_end_high, exec_low, exec_high, load_low, load_high]

                    # Parse addresses in little-endian format
                    exec_addr = (exec_high << 8) | exec_low
                    final_load_addr = (load_high << 8) | load_low

                    # Create the magic entry
                    magic_entry = MagicEntry(entry_type, data_values, exec_addr, final_load_addr, description)
                    self.magic_entries.append(magic_entry)

                except Exception as e:
                    print(f"Warning: Could not parse Magic10 EQUS line '{line}': {e}")
            else:
                # Try the alternative pattern for &FF entries
                ff_match = re.match(ff_pattern, line.strip())
            if ff_match:
                try:
                    entry_type = self.parse_hex_value(ff_match.group(1))
                    data_str = ff_match.group(2)

                    # For &FF entries: EQUS &FF,&FD,&7F,0,0,"Showpic #1",13
                    # Group 2: &FD (exec low), Group 3: &7F (exec high)
                    # Group 4: 0 (load low), Group 5: 0 (load high)
                    exec_low = self.parse_hex_value(ff_match.group(2))   # &FD
                    exec_high = self.parse_hex_value(ff_match.group(3)) # &7F
                    exec_addr = (exec_high << 8) | exec_low            # 0x7FFD

                    load_low = self.parse_hex_value(ff_match.group(4))   # 0
                    load_high = self.parse_hex_value(ff_match.group(5)) if ff_match.group(5) else 0
                    load_addr = (load_high << 8) | load_low

                    description = ff_match.group(6)

                    # Parse data section
                    data_values = self.parse_data_section(data_str)

                    # Create the magic entry
                    magic_entry = MagicEntry(entry_type, data_values, exec_addr, load_addr, description)
                    self.magic_entries.append(magic_entry)

                except Exception as e:
                    print(f"Warning: Could not parse EQUS line '{line}': {e}")
            else:
                print(f"Warning: Could not parse EQUS line '{line}': no pattern match")
    def parse_data_section(self, data_str: str) -> List[int]:
        """Parse the data section of an EQUS line"""
        data_values = []

        # Handle different data formats
        if not data_str or data_str == '0':
            return data_values

        # The data section can contain mixed formats
        # Let's handle this more carefully by looking for patterns

        # Check if it contains quoted strings
        if '"' in data_str:
            # Split by quotes and process each part
            parts = data_str.split('"')
            for i, part in enumerate(parts):
                if i % 2 == 1:  # This is a quoted string
                    for char in part:
                        data_values.append(ord(char))
                else:
                    # This is outside quotes, split by commas
                    sub_parts = part.split(',')
                    for sub_item in sub_parts:
                        sub_item = sub_item.strip()
                        if not sub_item:
                            continue

                        # Handle hex values (&xx)
                        if sub_item.startswith('&'):
                            try:
                                data_values.append(self.parse_hex_value(sub_item))
                            except:
                                pass
                        # Handle decimal numbers
                        elif sub_item.isdigit():
                            data_values.append(int(sub_item))
                        # Handle hex numbers without & prefix
                        elif all(c in '0123456789ABCDEFabcdef' for c in sub_item):
                            try:
                                data_values.append(int(sub_item, 16))
                            except:
                                pass
        else:
            # No quotes, just split by commas
            items = data_str.split(',')
            for item in items:
                item = item.strip()
                if not item:
                    continue

                # Handle hex values (&xx)
                if item.startswith('&'):
                    try:
                        data_values.append(self.parse_hex_value(item))
                    except:
                        pass
                # Handle decimal numbers
                elif item.isdigit():
                    data_values.append(int(item))
                # Handle hex numbers without & prefix
                elif all(c in '0123456789ABCDEFabcdef' for c in item):
                    try:
                        data_values.append(int(item, 16))
                    except:
                        pass
                # Handle single characters (like ' ')
                elif item.startswith("'") and item.endswith("'") and len(item) == 3:
                    data_values.append(ord(item[1]))
                # Handle special cases like (C)
                elif item.startswith('(') and item.endswith(')'):
                    for char in item[1:-1]:
                        data_values.append(ord(char))

        return data_values

    def process_magic_entry(self, entry_data: dict):
        """Process a parsed magic entry and add it to the entries list"""
        self.magic_entries.append(MagicEntry(
            entry_data['type'],
            entry_data['data'],
            entry_data['exec'],
            entry_data['load'],
            entry_data['description']
        ))

    def parse_hex_value(self, hex_str: str) -> int:
        """Parse a hex value from string (handles &xx format)"""
        hex_str = hex_str.strip()
        if hex_str.startswith('&'):
            hex_str = hex_str[1:]
        return int(hex_str, 16)

    def load_fallback_magic_data(self):
        """Fallback hardcoded magic data in case MAGIC_SOURCE.ASM is not available"""
        # Entry type 9: String matching anywhere in first page
        self.magic_entries.append(MagicEntry(9, [5, ord('<'), ord('&'), ord('>'), ord('E'), ord('0'), ord('0')], 0x8023, 0x0E, "Basic page=&E00 #1"))
        self.magic_entries.append(MagicEntry(9, [6, ord('<'), ord('&'), ord('>'), ord('1'), ord('1'), ord('0'), ord('0')], 0x8023, 0x11, "Basic page=&1100 #1"))

        # Entry type 1: Offset + pattern matching
        self.magic_entries.append(MagicEntry(1, [0, 1, 0x0D, 0x00], 0x8023, 0x00, "Basic #1"))

        # Entry type 4: BASIC programs
        self.magic_entries.append(MagicEntry(4, [0x23, 0x80], 0x8023, 0x00, "Basic #2"))

        # Entry type 5: Text/Word detection
        self.magic_entries.append(MagicEntry(5, [2, 0x20, 0, ord('e'), 0], 0x7FFC, 0x00, "text/word #1"))
        self.magic_entries.append(MagicEntry(5, [2, 0x20, 0, ord('E'), 0], 0x7FFC, 0x00, "text/word #2"))

        # Entry type 7: Letter frequency counting
        self.magic_entries.append(MagicEntry(7, [110, 8, ord('a'), ord('e'), ord('h'), ord('i'), ord('n'), ord('o'), ord('r'), ord('s'), ord('t')], 0x7FFC, 0x00, "text/word #3"))

        # End marker
        self.magic_entries.append(MagicEntry(0, [], 0x0000, 0x00, ""))

    def load_file(self, filename: str) -> bool:
        """Load the first 256 bytes of a file and read .inf file for current addresses"""
        try:
            # First try to read the .inf file for current load/exec addresses
            inf_filename = filename + '.inf'
            try:
                with open(inf_filename, 'r') as inf_file:
                    inf_content = inf_file.read().strip()
                    # Parse format: "filename load_addr exec_addr CRC=xxxx"
                    parts = inf_content.split()
                    if len(parts) >= 3:
                        self.current_load = int(parts[1], 16)
                        self.current_exec = int(parts[2], 16)
            except FileNotFoundError:
                # No .inf file, use defaults
                self.current_load = 0
                self.current_exec = 0
            except Exception as e:
                print(f"Warning: Could not parse .inf file {inf_filename}: {e}")
                self.current_load = 0
                self.current_exec = 0

            # Now load the actual file data
            with open(filename, 'rb') as f:
                # Read first page (256 bytes)
                data = f.read(256)
                self.raw_data = [b for b in data] + [0] * (256 - len(data))

                # Try to get file size
                f.seek(0, 2)  # Seek to end
                self.file_size = f.tell()

            return True
        except Exception as e:
            print(f"Error loading file: {e}")
            return False

    def analyze_file(self, filename: str) -> Dict[str, Any]:
        """Analyze a file and return the results"""
        if not self.load_file(filename):
            return {"error": "Could not load file"}

        results = {
            "filename": filename,
            "file_size": self.file_size,
            "current_load": self.current_load,
            "current_exec": self.current_exec,
            "analysis": []
        }

        # Check if addresses are already set (mimics the alreadyset check in assembly)
        if self.current_exec >= 0x7F00:
            # If we have a meaningful match, show it instead of "Magic already set"
            if results["analysis"]:
                # Show the first meaningful match
                return results
            else:
                # Check if this is a Magic10 match that should still be processed
                for magic in self.magic_entries:
                    if magic.entry_type == 0:  # End marker
                        break

                    if magic.entry_type == 10:  # Magic10 entries should still be processed
                        match_result = self.test_magic_entry(magic)
                        if match_result["matched"]:
                            results["analysis"].append({
                                "description": magic.description,
                                "exec_addr": magic.exec_addr,
                                "load_addr": magic.load_addr,
                                "test_type": magic.entry_type
                            })
                            return results

                print("Magic already set")
                return results

        # Run magic analysis (mimics the TableScan loop in assembly)
        # First pass: look for non-text matches
        for magic in self.magic_entries:
            if magic.entry_type == 0:  # End marker
                break

            # Skip text/word entries in first pass
            if "text/word" in magic.description:
                continue

            match_result = self.test_magic_entry(magic)
            if match_result["matched"]:
                results["analysis"].append({
                    "description": magic.description,
                    "exec_addr": magic.exec_addr,
                    "load_addr": magic.load_addr,
                    "test_type": magic.entry_type
                })

                # Update current addresses if not already set
                if magic.exec_addr not in [0, 0x7FFC] and self.current_exec == 0:
                    self.current_exec = magic.exec_addr
                if magic.load_addr != 0 and self.current_load == 0:
                    self.current_load = magic.load_addr

        # Second pass: only add text/word if no other matches found
        if not results["analysis"]:
            for magic in self.magic_entries:
                if magic.entry_type == 0:  # End marker
                    break

                if "text/word" in magic.description:
                    match_result = self.test_magic_entry(magic)
                    if match_result["matched"]:
                        results["analysis"].append({
                            "description": magic.description,
                            "exec_addr": magic.exec_addr,
                            "load_addr": magic.load_addr,
                            "test_type": magic.entry_type
                        })

                        # Update current addresses for text matches
                        if self.current_exec == 0:
                            self.current_exec = magic.exec_addr
                        if self.current_load == 0:
                            self.current_load = magic.load_addr

        # Screen mode detection (separate from magic tests)
        screen_mode = self.detect_screen_mode()
        if screen_mode:
            results["screen_mode"] = screen_mode

        return results

    def test_magic_entry(self, magic: MagicEntry) -> Dict[str, Any]:
        """Test a single magic entry against the file data"""
        if magic.entry_type == 1:
            return self.test_magic1(magic)
        elif magic.entry_type == 2:
            return self.test_magic2(magic)
        elif magic.entry_type == 3:
            return self.test_magic3(magic)
        elif magic.entry_type == 4:
            return self.test_magic4(magic)
        elif magic.entry_type == 5:
            return self.test_magic5(magic)
        elif magic.entry_type == 6:
            return self.test_magic6(magic)
        elif magic.entry_type == 7:
            return self.test_magic7(magic)
        elif magic.entry_type == 8:
            return self.test_magic8(magic)
        elif magic.entry_type == 9:
            return self.test_magic9(magic)
        elif magic.entry_type == 10:
            return self.test_magic10(magic)
        elif magic.entry_type == 0xFF:
            return self.test_magic_ff(magic)
        else:
            return {"matched": False}

    def test_magic1(self, magic: MagicEntry) -> Dict[str, Any]:
        """Test Magic1: Offset + byte pattern matching"""
        if len(magic.data) < 2:
            return {"matched": False}

        offset = magic.data[0]
        pattern = magic.data[1:]

        if offset + len(pattern) > 256:
            return {"matched": False}

        # Check if pattern matches at offset
        for i, byte_val in enumerate(pattern):
            if self.raw_data[offset + i] != byte_val:
                return {"matched": False}

        return {"matched": True}

    def test_magic2(self, magic: MagicEntry) -> Dict[str, Any]:
        """Test Magic2: Byte range + value range checking"""
        if len(magic.data) < 4:
            return {"matched": False}

        start_range = magic.data[0]
        end_range = magic.data[1]
        min_value = magic.data[2] + (magic.data[3] << 8)  # Little endian

        # Calculate highest byte (equivalent to GethighestByte subroutine)
        highest_byte = 0
        byte_counts = [0] * 256

        for byte_val in self.raw_data:
            byte_counts[byte_val] += 1
            if byte_counts[byte_val] > byte_counts[highest_byte]:
                highest_byte = byte_val

        # Check conditions
        if not (start_range <= highest_byte <= end_range):
            return {"matched": False}

        # Calculate total bytes (equivalent to noofbytes)
        total_bytes = sum(byte_counts)

        if total_bytes < min_value:
            return {"matched": False}

        return {"matched": True}

    def test_magic3(self, magic: MagicEntry) -> Dict[str, Any]:
        """Test Magic3: Load address matching"""
        if len(magic.data) < 2:
            return {"matched": False}

        load_addr = magic.data[0] + (magic.data[1] << 8)  # Little endian

        return {"matched": (self.current_load & 0xFFFF) == load_addr}

    def test_magic4(self, magic: MagicEntry) -> Dict[str, Any]:
        """Test Magic4: Execution address matching"""
        if len(magic.data) < 2:
            return {"matched": False}

        exec_addr = magic.data[0] + (magic.data[1] << 8)  # Little endian

        return {"matched": (self.current_exec & 0xFFFF) == exec_addr}

    def test_magic5(self, magic: MagicEntry) -> Dict[str, Any]:
        """Test Magic5: Byte frequency analysis"""
        if len(magic.data) < 3:
            return {"matched": False}

        num_pairs = magic.data[0]
        expected_pairs = []

        # Parse expected byte/count pairs
        for i in range(num_pairs):
            if len(magic.data) < 3 + i * 2:
                return {"matched": False}
            byte_val = magic.data[1 + i * 2]
            count = magic.data[2 + i * 2]
            expected_pairs.append((byte_val, count))

        # Count actual frequencies
        byte_counts = [0] * 256
        for byte_val in self.raw_data:
            byte_counts[byte_val] += 1

        # Check if all expected pairs match
        for byte_val, expected_count in expected_pairs:
            if byte_counts[byte_val] < expected_count:
                return {"matched": False}

        return {"matched": True}

    def test_magic6(self, magic: MagicEntry) -> Dict[str, Any]:
        """Test Magic6: Offset + byte pattern matching variant"""
        if len(magic.data) < 3:
            return {"matched": False}

        offset = magic.data[0]
        pattern_len = magic.data[1]
        pattern = magic.data[2:2+pattern_len]

        if offset + pattern_len > 256:
            return {"matched": False}

        # Check if pattern matches at offset
        for i, byte_val in enumerate(pattern):
            if self.raw_data[offset + i] != byte_val:
                return {"matched": False}

        return {"matched": True}

    def test_magic7(self, magic: MagicEntry) -> Dict[str, Any]:
        """Test Magic7: Letter frequency counting"""
        if len(magic.data) < 2:
            return {"matched": False}

        min_count = magic.data[0]
        num_letters = magic.data[1]
        letters = magic.data[2:2+num_letters]

        if len(letters) != num_letters:
            return {"matched": False}

        # Count frequency of specified letters
        total_count = 0
        for byte_val in self.raw_data:
            if byte_val in letters:
                total_count += 1

        return {"matched": total_count >= min_count}

    def test_magic8(self, magic: MagicEntry) -> Dict[str, Any]:
        """Test Magic8: File size matching"""
        if len(magic.data) < 2:
            return {"matched": False}

        size_value = magic.data[0] + (magic.data[1] << 8)  # Little endian

        return {"matched": self.file_size == size_value}

    def test_magic9(self, magic: MagicEntry) -> Dict[str, Any]:
        """Test Magic9: String search in first page"""
        if len(magic.data) < 1:
            return {"matched": False}

        pattern_len = magic.data[0]
        pattern = magic.data[1:1+pattern_len]

        # Search for pattern anywhere in first page
        for i in range(257 - pattern_len):
            match = True
            for j, byte_val in enumerate(pattern):
                if self.raw_data[i + j] != byte_val:
                    match = False
                    break
            if match:
                return {"matched": True}

        return {"matched": False}

    def test_magic_ff(self, magic: MagicEntry) -> Dict[str, Any]:
        """Test MagicFF: Special entries"""
        # These are special markers, always return not matched
        # as they're handled differently in the original code
        return {"matched": False}

    def test_magic10(self, magic: MagicEntry) -> Dict[str, Any]:
        """Test Magic10: rune00.asm ending detection with offset from end"""
        if len(magic.data) < 7:
            return {"matched": False}

        # Parse Magic10 data format: [load_addr, offset_from_end_low, offset_from_end_high, exec_low, exec_high, load_low, load_high]
        offset_from_end = magic.data[2] + (magic.data[1] << 8)  # Little endian offset from end (high, low)
        exec_base = magic.data[4] + (magic.data[3] << 8)         # Little endian exec base (high, low)

        # Calculate expected execution address: current_load + file_size - offset_from_end
        calculated_exec = self.current_load + self.file_size - offset_from_end


        # Check if current execution address matches the calculated value
        return {"matched": self.current_exec == calculated_exec}


    def detect_screen_mode(self) -> Optional[int]:
        """Screen mode detection is now handled by MAGIC_SOURCE.ASM entries"""
        # Screen mode detection is now integrated into the magic data parsing
        # The detect_screen_mode function is kept for compatibility but should return None
        # as screen modes are now handled as magic entries in MAGIC_SOURCE.ASM
        return None


def main():
    """Main function to analyze files"""
    if len(sys.argv) < 2:
        # No arguments - show help (equivalent to MAGICHELPPRINT)
        analyzer = MagicAnalyzer()
        print("MAGIC - File Type Detection Program")
        print("==================================")
        print()
        print("Usage: python magic.py <filename> [--csv]")
        print("  --csv    Output results in CSV format")
        print()
        print("Supported file types and their magic signatures:")
        print()

        # Display all magic entries (equivalent to MAGICHELPPRINT)
        # Verbose format: just show the description with addresses
        # Collect all unique entries first, then sort by exec address
        unique_entries = []

        for magic in analyzer.magic_entries:
            if magic.entry_type == 0:  # End marker
                break

            # Create a unique key for this entry (addresses only, since descriptions vary)
            entry_key = (magic.exec_addr, magic.load_addr)

            # Check if we already have this address combination
            already_exists = False
            for existing in unique_entries:
                if existing[0] == magic.exec_addr and existing[1] == magic.load_addr:
                    already_exists = True
                    break

            if not already_exists:
                unique_entries.append((magic.exec_addr, magic.load_addr, magic.description))

        # Sort by exec address
        unique_entries.sort(key=lambda x: x[0])

        # Display sorted entries
        for exec_addr, load_addr, description in unique_entries:
            # Format: "Exec: D9CD, Load: 8000 Rom #1"
            # Extract the key part before the number (e.g., "Rom")
            desc_parts = description.split('#')
            if len(desc_parts) > 1:
                short_desc = desc_parts[0]
            else:
                short_desc = description

            print(f"  Exec: {exec_addr:04X}, Load: {load_addr:04X} {short_desc}")

        return

    # Check for CSV output flag
    csv_output = "--csv" in sys.argv
    filename = sys.argv[1] if sys.argv[1] != "--csv" else sys.argv[2]

    analyzer = MagicAnalyzer()
    results = analyzer.analyze_file(filename)

    if "error" in results:
        print(f"Error: {results['error']}")
        sys.exit(1)

    if csv_output:
        # Output in CSV format for integration with existing CSV
        print("Filename,MagicType,Description,ExecAddr,LoadAddr,ScreenMode,FileSize")
        magic_types = []
        for analysis in results['analysis']:
            magic_types.append(f"Type{analysis['test_type']}")

        magic_type_str = "|".join(magic_types) if magic_types else "None"

        screen_mode = results.get('screen_mode', 'None')

        print(f"{results['filename']},{magic_type_str},{results['analysis'][0]['description'] if results['analysis'] else 'None'},{results['current_exec']:04X},{results['current_load']:04X},{screen_mode},{results['file_size']}")
    else:
        # Human-readable output
        print(f"File: {results['filename']}")
        print(f"Size: {results['file_size']}")
        print(f"Current Load: {results['current_load']:04X}")
        print(f"Current Exec: {results['current_exec']:04X}")

        if results['analysis']:
            print("\nMagic Analysis Results:")
            for analysis in results['analysis']:
                print(f"  {analysis['description']}")
                print(f"    Exec: {analysis['exec_addr']:04X}")
                print(f"    Load: {analysis['load_addr']:04X}")

        if "screen_mode" in results:
            print(f"\nDetected Screen Mode: {results['screen_mode']}")


if __name__ == "__main__":
    main()