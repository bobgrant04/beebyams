#!/usr/bin/env python3
"""
kilo_ssd_processor.py - SSD file processing and CSV extraction for Kilo utilities

This module processes SSD files using the existing getfile.pl script and extracts
information to CSV format.
Environment: Windows 11
Author: Kilo Code
"""

import os
import sys
import shutil
import subprocess
from pathlib import Path
from typing import List, Dict, Any, Union
import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from kilo_logger import logger, debug_print
from kilo_file_utils import FileInfoExtractor, CSVWriter, get_ssd_filename

class SSDProcessor:
    """Processes SSD files and extracts information to CSV."""

    def __init__(self, getfile_pl_path: str = "getfile.pl"):
        self.getfile_pl_path = getfile_pl_path
        self._verify_dependencies()

    def _verify_dependencies(self) -> None:
        """Verify that required dependencies are available."""
        # Check if getfile.pl exists
        if not os.path.exists(self.getfile_pl_path):
            raise FileNotFoundError(f"getfile.pl not found at: {self.getfile_pl_path}")

        # Check if Perl is available
        try:
            result = subprocess.run(['perl', '--version'],
                                  capture_output=True, text=True, check=True)
            debug_print(f"Perl version: {result.stderr.strip()}")
        except (subprocess.CalledProcessError, FileNotFoundError):
            raise EnvironmentError("Perl is not installed or not in PATH")

    def process_single_ssd(self, ssd_path: str, output_csv: str = "roo_myinfo.csv") -> int:
        """
        Process a single SSD file and extract information to CSV.

        Args:
            ssd_path: Path to the SSD file
            output_csv: Path to output CSV file

        Returns:
            Number of files processed
        """
        ssd_file = Path(ssd_path)

        if not ssd_file.exists():
            raise FileNotFoundError(f"SSD file not found: {ssd_path}")

        if not ssd_file.suffix.lower() == '.ssd':
            raise ValueError(f"File is not an SSD file: {ssd_path}")

        logger.info(f"Processing SSD file: {ssd_file.name}")
        debug_print(f"Full path: {ssd_file.absolute()}")

        # Generate a unique temp directory name that doesn't exist yet
        temp_dir_name = self._generate_unique_temp_dir_name(f"ssd_extract_{ssd_file.stem}")

        try:
            # Extract SSD contents using getfile.pl (it will create the directory)
            self._extract_ssd_contents(str(ssd_file), temp_dir_name)

            # Extract information from extracted files
            extractor = FileInfoExtractor(temp_dir_name)
            ssd_name = get_ssd_filename(str(ssd_file))
            file_info_list = extractor.extract_all_files_info(ssd_name)

            if not file_info_list:
                logger.warning(f"No files extracted from {ssd_file.name}")
                return 0

            # Write to CSV
            csv_writer = CSVWriter(output_csv)
            csv_writer.write_to_csv(file_info_list)

            logger.info(f"Successfully processed {ssd_file.name}: {len(file_info_list)} files")
            return len(file_info_list)

        finally:
            # Clean up temp directory
            self._cleanup_temp_dir(temp_dir_name)

    def process_ssd_directory(self, directory_path: str, output_csv: str = "roo_myinfo.csv") -> Dict[str, int]:
        """
        Process all SSD files in a directory.

        Args:
            directory_path: Path to directory containing SSD files
            output_csv: Path to output CSV file

        Returns:
            Dictionary with SSD filenames as keys and file counts as values
        """
        directory = Path(directory_path)

        if not directory.exists():
            raise FileNotFoundError(f"Directory not found: {directory_path}")

        if not directory.is_dir():
            raise ValueError(f"Path is not a directory: {directory_path}")

        # Find all .ssd files
        ssd_files = list(directory.glob("*.ssd"))
        debug_print(f"Found {len(ssd_files)} SSD files in {directory}")

        if not ssd_files:
            logger.warning(f"No SSD files found in {directory}")
            return {}

        results = {}
        total_files = 0

        for ssd_file in ssd_files:
            try:
                file_count = self.process_single_ssd(str(ssd_file), output_csv)
                results[ssd_file.name] = file_count
                total_files += file_count

            except Exception as e:
                logger.error(f"Failed to process {ssd_file.name}: {e}")
                results[ssd_file.name] = 0

        logger.info(f"Processed {len(ssd_files)} SSD files, extracted {total_files} total files")
        return results

    def _extract_ssd_contents(self, ssd_path: str, temp_dir: str) -> None:
        """
        Extract SSD contents using getfile.pl script.

        Args:
            ssd_path: Path to SSD file
            temp_dir: Temporary directory for extraction (will be created by getfile.pl)
        """
        debug_print(f"Extracting {ssd_path} to {temp_dir}")

        # Ensure the temp directory doesn't exist yet (getfile.pl will create it)
        if os.path.exists(temp_dir):
            raise RuntimeError(f"Temp directory already exists: {temp_dir}")

        try:
            # Run getfile.pl script
            cmd = ['perl', self.getfile_pl_path, ssd_path, temp_dir]
            debug_print(f"Running command: {' '.join(cmd)}")

            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                cwd=os.getcwd(),  # Run from current working directory
                check=True
            )

            debug_print(f"getfile.pl stdout: {result.stdout}")
            if result.stderr:
                debug_print(f"getfile.pl stderr: {result.stderr}")

            # Verify the directory was created and has content
            if not os.path.exists(temp_dir):
                raise RuntimeError(f"getfile.pl did not create temp directory: {temp_dir}")

            file_count = len([f for f in os.listdir(temp_dir) if not f.startswith('.')])
            logger.info(f"Successfully extracted {ssd_path} to {temp_dir} ({file_count} files)")

        except subprocess.CalledProcessError as e:
            logger.error(f"getfile.pl failed for {ssd_path}:")
            logger.error(f"Return code: {e.returncode}")
            logger.error(f"Stdout: {e.stdout}")
            logger.error(f"Stderr: {e.stderr}")
            raise RuntimeError(f"Failed to extract SSD contents: {e}")

    def _generate_unique_temp_dir_name(self, base_name: str) -> str:
        """Generate a unique temporary directory name that doesn't exist."""
        import time
        import random

        # Clean the base name for Windows compatibility
        safe_base_name = "".join(c for c in base_name if c.isalnum() or c in ('_', '-')).strip()
        if not safe_base_name:
            safe_base_name = "temp"

        # Generate a unique directory name that doesn't exist
        max_attempts = 100

        for attempt in range(max_attempts):
            # Create a unique suffix using timestamp and random number
            timestamp = str(int(time.time() * 1000000))[-8:]  # Last 8 digits of microsecond timestamp
            random_suffix = str(random.randint(1000, 9999))
            dir_name = f"{safe_base_name}_{timestamp}_{random_suffix}"
            temp_dir = os.path.join(os.getcwd(), dir_name)

            if not os.path.exists(temp_dir):
                debug_print(f"Generated unique temp directory name: {temp_dir}")
                return temp_dir

        raise RuntimeError(f"Could not generate unique temp directory name after {max_attempts} attempts")

    def _cleanup_temp_dir(self, temp_dir: str) -> None:
        """Clean up temporary directory."""
        if os.path.exists(temp_dir):
            try:
                shutil.rmtree(temp_dir)
                debug_print(f"Cleaned up temp directory: {temp_dir}")
            except Exception as e:
                logger.warning(f"Failed to cleanup temp directory {temp_dir}: {e}")

    def process_input(self, input_path: str, output_csv: str = "roo_myinfo.csv") -> Dict[str, int]:
        """
        Process input (single file or directory) and extract to CSV.

        Args:
            input_path: Path to SSD file or directory containing SSD files
            output_csv: Path to output CSV file

        Returns:
            Dictionary with processing results
        """
        path = Path(input_path)

        if path.is_file():
            # Single SSD file
            count = self.process_single_ssd(input_path, output_csv)
            return {path.name: count}

        elif path.is_dir():
            # Directory of SSD files
            return self.process_ssd_directory(input_path, output_csv)

        else:
            raise ValueError(f"Input path does not exist: {input_path}")

def main():
    """Main function for command-line usage."""
    if len(sys.argv) < 2:
        print("Usage: python kilo_ssd_processor.py <ssd_file_or_directory> [output_csv]")
        print("Example: python kilo_ssd_processor.py data/altD002b.ssd")
        print("Example: python kilo_ssd_processor.py ./disks/")
        sys.exit(1)

    input_path = sys.argv[1]
    output_csv = sys.argv[2] if len(sys.argv) > 2 else "roo_myinfo.csv"

    try:
        processor = SSDProcessor()
        results = processor.process_input(input_path, output_csv)

        print(f"\nProcessing complete!")
        print(f"Output written to: {output_csv}")
        print(f"Results: {results}")

    except Exception as e:
        logger.error(f"Processing failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()