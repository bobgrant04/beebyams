#!/usr/bin/env python3
"""
kilo_file_utils.py - File operations and parsing utilities for Kilo utilities

This module provides utilities for parsing .inf files, handling file operations,
and extracting information from SSD extracted files.
Environment: Windows 11
Author: Kilo Code
"""

import os
import re
import csv
from pathlib import Path
from typing import Dict, List, Tuple, Optional, Any

from kilo_logger import logger, debug_print

class InfFileParser:
    """Parser for .inf files extracted from SSD images."""

    # Regex pattern for parsing .inf file format: filename load_addr exec_addr [Locked] CRC=xxxx
    INF_PATTERN = re.compile(
        r'^(.+?)\s+(\w+)\s+(\w+)(?:\s+Locked)?\s+CRC=(\w+)$'
    )

    @staticmethod
    def parse_inf_file(inf_file_path: str) -> Optional[Dict[str, Any]]:
        """
        Parse a .inf file and extract file information.

        Args:
            inf_file_path: Path to the .inf file

        Returns:
            Dictionary containing filename, load_address, exec_address, crc, and locked status
            Returns None if parsing fails
        """
        try:
            with open(inf_file_path, 'r', encoding='utf-8') as f:
                line = f.readline().strip()

            debug_print(f"Parsing .inf file: {inf_file_path}")
            debug_print(f"Content: {line}")

            match = InfFileParser.INF_PATTERN.match(line)
            if not match:
                logger.warning(f"Failed to parse .inf file: {inf_file_path}")
                logger.warning(f"Content: {line}")
                return None

            filename, load_addr, exec_addr, crc = match.groups()

            return {
                'filename': filename.strip(),
                'load_address': load_addr.upper(),
                'exec_address': exec_addr.upper(),
                'crc': crc.upper(),
                'locked': 'Locked' in line
            }

        except Exception as e:
            logger.error(f"Error parsing .inf file {inf_file_path}: {e}")
            return None

class FileInfoExtractor:
    """Extracts information from paired data and .inf files."""

    def __init__(self, temp_dir: str):
        self.temp_dir = Path(temp_dir)
        self.extracted_files = []

    def find_file_pairs(self) -> List[Tuple[Path, Path]]:
        """
        Find paired data and .inf files in the temp directory.

        Returns:
            List of tuples (data_file, inf_file)
        """
        pairs = []
        debug_print(f"Scanning directory for file pairs: {self.temp_dir}")

        # Get all .inf files
        inf_files = list(self.temp_dir.glob("*.inf"))
        debug_print(f"Found {len(inf_files)} .inf files")

        for inf_file in inf_files:
            data_file = inf_file.with_suffix("")  # Remove .inf extension

            if data_file.exists():
                pairs.append((data_file, inf_file))
                debug_print(f"Found pair: {data_file.name} <-> {inf_file.name}")
            else:
                logger.warning(f"Found .inf file without matching data file: {inf_file}")

        debug_print(f"Total pairs found: {len(pairs)}")
        return pairs

    def extract_file_info(self, data_file: Path, inf_file: Path, ssd_path: str) -> Optional[Dict[str, Any]]:
        """
        Extract information from a file pair.

        Args:
            data_file: Path to the data file
            inf_file: Path to the .inf file
            ssd_path: Full path of the source SSD file

        Returns:
            Dictionary containing extracted information or None if extraction fails
        """
        try:
            # Parse .inf file
            inf_info = InfFileParser.parse_inf_file(str(inf_file))
            if not inf_info:
                return None

            # Get file size
            file_size = data_file.stat().st_size

            # Extract directory (parent directory of SSD file)
            ssd_file_path = Path(ssd_path)
            directory = ssd_file_path.parent.name if ssd_file_path.parent.name else "."

            # Get SSD filename without extension
            ssd_name = ssd_file_path.stem

            debug_print(f"Extracted info for {data_file.name}:")
            debug_print(f"  Directory: {directory}")
            debug_print(f"  SSD: {ssd_name}")
            debug_print(f"  Filename: {inf_info['filename']}")
            debug_print(f"  Load: {inf_info['load_address']}")
            debug_print(f"  Exec: {inf_info['exec_address']}")
            debug_print(f"  CRC: {inf_info['crc']}")
            debug_print(f"  Size: {file_size}")

            return {
                'directory': directory,
                'ssd_file': ssd_name,
                'filename': inf_info['filename'],
                'load_address': inf_info['load_address'],
                'execute_address': inf_info['exec_address'],
                'crc': inf_info['crc'],
                'file_length': file_size,
                'locked': inf_info['locked']
            }

        except Exception as e:
            logger.error(f"Error extracting info from {data_file}: {e}")
            return None

    def extract_all_files_info(self, ssd_path: str) -> List[Dict[str, Any]]:
        """
        Extract information from all file pairs in the temp directory.

        Args:
            ssd_path: Full path of the source SSD file

        Returns:
            List of dictionaries containing extracted information
        """
        file_pairs = self.find_file_pairs()
        extracted_info = []

        for data_file, inf_file in file_pairs:
            info = self.extract_file_info(data_file, inf_file, ssd_path)
            if info:
                extracted_info.append(info)

        ssd_name = Path(ssd_path).stem
        logger.info(f"Extracted information for {len(extracted_info)} files from {ssd_name}")
        return extracted_info

class CSVWriter:
    """Handles writing extracted information to CSV files."""

    def __init__(self, csv_path: str):
        self.csv_path = csv_path
        self.fieldnames = ['directory', 'ssd_file', 'filename', 'load_address', 'execute_address', 'crc', 'file_length']

    def write_to_csv(self, file_info_list: List[Dict[str, Any]], append: bool = True) -> None:
        """
        Write file information to CSV file.

        Args:
            file_info_list: List of dictionaries containing file information
            append: If True, append to existing file; if False, overwrite
        """
        mode = 'a' if append else 'w'
        debug_print(f"Writing {len(file_info_list)} records to CSV: {self.csv_path}")

        try:
            with open(self.csv_path, mode, newline='', encoding='utf-8') as csvfile:
                writer = csv.DictWriter(csvfile, fieldnames=self.fieldnames)

                # Write header only if creating new file
                if not append or (append and csvfile.tell() == 0):
                    writer.writeheader()
                    debug_print("Wrote CSV header")

                for info in file_info_list:
                    # Create a clean record for CSV writing
                    record = {
                        'directory': info['directory'],
                        'ssd_file': info['ssd_file'],
                        'filename': info['filename'],
                        'load_address': info['load_address'],
                        'execute_address': info['execute_address'],
                        'crc': info['crc'],
                        'file_length': info['file_length']
                    }
                    writer.writerow(record)

            if file_info_list:
                logger.info(f"Successfully wrote {len(file_info_list)} records to {self.csv_path}")
            else:
                logger.info(f"CSV file created/updated with headers: {self.csv_path}")

        except Exception as e:
            logger.error(f"Error writing to CSV {self.csv_path}: {e}")
            raise

    def ensure_csv_exists(self, output_csv: str) -> None:
        """
        Ensure CSV file exists with proper headers.

        Args:
            output_csv: Path to CSV file to create
        """
        if not os.path.exists(output_csv):
            debug_print(f"Creating new CSV file: {output_csv}")
            self.write_to_csv([], append=False)

def get_ssd_filename(ssd_path: str) -> str:
    """Extract filename from SSD path."""
    return Path(ssd_path).stem

def create_temp_dir(base_name: str) -> str:
    """Create a unique temporary directory."""
    import tempfile
    # Create a safe directory name for Windows
    safe_base_name = "".join(c for c in base_name if c.isalnum() or c in ('_', '-')).strip()
    if not safe_base_name:
        safe_base_name = "temp"

    # Use tempfile.mkdtemp with a prefix to avoid issues
    temp_dir = tempfile.mkdtemp(prefix=f"{safe_base_name}_", dir=os.getcwd())
    debug_print(f"Created temp directory: {temp_dir}")
    return temp_dir