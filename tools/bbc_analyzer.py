import os
import re
import sys

# Load magic table once at startup
magic_table = None

def load_magic_table():
    global magic_table
    try:
        magic_table = {}
        with open("MAGIC_SOURCE.ASM", "r") as f:
            for line in f:
                line = line.strip()
                if not line.startswith("EQUS"):
                    continue
                    
                parts = line.split(',')
                # Skip lines with insufficient parts
                if len(parts) < 3:
                    continue
                    
                # Extract description from quoted string
                description = None
                for part in parts:
                    part = part.strip()
                    if part.startswith('"') and part.endswith('"'):
                        description = part[1:-1].strip()
                        break
                if not description:
                    continue
                
                # Process pattern bytes (skip EQUS and last part)
                pattern = []
                for part in parts[1:-2]:
                    part = part.strip()
                    if part.startswith('&') and len(part) > 1:
                        hex_val = part.strip('&')
                        if hex_val:
                            try:
                                byte = int(hex_val, 16)
                                pattern.append(byte)
                            except ValueError:
                                continue
                if len(pattern) >= 2:
                    magic_table[bytes(pattern[:2])] = description
    except Exception as e:
        print(f"Error loading magic table: {e}")
        return None

def analyze_file(filename):
    global magic_table
    if magic_table is None:
        load_magic_table()
    
    try:
        with open(filename, 'rb') as f:
            header = f.read(2)
    except Exception as e:
        return f"Error analyzing {filename}: {e}"
    
    for pattern, description in magic_table.items():
        if header == pattern:
            return f"{os.path.basename(filename)}: {description}"
    return f"{os.path.basename(filename)}: Unknown"

def main():
    global magic_table
    
    # Check if command-line argument is provided
    if len(sys.argv) > 1:
        input_path = sys.argv[1]
        base_name = os.path.splitext(os.path.basename(input_path))[0]
        
        # Remove trailing digits from base name
        base_name = re.sub(r'\d+$', '', base_name)
        inf_path = f"{base_name}.inf"
        
        # Process the specified file and its .inf counterpart
        print(f"Analyzing {input_path}...")
        result_ssd = analyze_file(input_path)
        print(f"{input_path}: {result_ssd}")
        
        if os.path.exists(inf_path):
            try:
                with open(inf_path, 'r') as f:
                    content = f.read()
                if "ROM" in content or "BASIC" in content:
                    print(f"{inf_path}: ROM/BASIC info")
                else:
                    print(f"{inf_path}: Unknown")
            except Exception as e:
                print(f"Error analyzing {inf_path}: {e}")
        else:
            print(f"{inf_path}: No .inf file found")
    else:
        directory = "Disk Collections/rom ($.rom.csv)/"
        print(f"Processing files in directory: {directory}")
        for filename in os.listdir(directory):
            if filename.endswith('.ssd'):
                base_name = os.path.splitext(filename)[0]
                # Remove trailing digits from base name
                base_name = re.sub(r'\d+$', '', base_name)
                inf_filename = f"{base_name}.inf"
                full_ssd_path = os.path.join(directory, filename)
                full_inf_path = os.path.join(directory, inf_filename)
                
                # Process .ssd file
                result_ssd = analyze_file(full_ssd_path)
                print(f"{filename}: {result_ssd}")
                
                # Process .inf file if exists
                if os.path.exists(full_inf_path):
                    try:
                        with open(full_inf_path, 'r') as f:
                            content = f.read()
                        if "ROM" in content or "BASIC" in content:
                            print(f"{inf_filename}: ROM/BASIC info")
                        else:
                            print(f"{inf_filename}: Unknown")
                    except Exception as e:
                        print(f"Error analyzing {inf_filename}: {e}")
                else:
                    print(f"{inf_filename}: No .inf file found")

if __name__ == "__main__":
    main()