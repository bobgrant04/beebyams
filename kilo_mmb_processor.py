#!/usr/bin/env python3
"""
kilo_mmb_processor.py - MMB file processing utilities for Kilo utilities

This module handles MMB (Multi-Menu BBC disk) file processing including
catalogue reading, SSD extraction, and integration with the main SSD processor.
Environment: Windows 11
Author: Kilo Code
"""

import os
import sys
import subprocess
import shutil
from pathlib import Path
from typing import List, Dict, Any
import re


from kilo_logger import logger, debug_print

class MMBProcessor:
    """Handles MMB file processing including catalogue reading and SSD extraction."""

    def __init__(self):
        self._verify_dependencies()

    def _verify_dependencies(self) -> None:
        """Verify that MMB processing dependencies are available."""
        # Check if dcat.pl exists for MMB support
        dcat_path = "tools/dcat.pl"
        if not os.path.exists(dcat_path):
            raise FileNotFoundError(f"dcat.pl not found at: {dcat_path}")

        # Check if dget_ssd.pl exists for MMB support
        dget_ssd_path = "tools/dget_ssd.pl"
        if not os.path.exists(dget_ssd_path):
            raise FileNotFoundError(f"dget_ssd.pl not found at: {dget_ssd_path}")

        # Check if Perl is available
        try:
            result = subprocess.run(['perl', '--version'],
                                  capture_output=True, text=True, check=True)
            debug_print(f"Perl version: {result.stderr.strip()}")
        except (subprocess.CalledProcessError, FileNotFoundError):
            raise EnvironmentError("Perl is not installed or not in PATH")

    def get_mmb_catalogue(self, mmb_path: str) -> List[Dict[str, Any]]:
        """
        Get the catalogue of disks in an MMB file using dcat.pl.

        Args:
            mmb_path: Path to the MMB file

        Returns:
            List of dictionaries containing disk information
        """
        debug_print(f"Getting MMB catalogue for: {mmb_path}")

        try:
            # Set BEEB_UTILS_DFS environment variable to ensure ACORN format
            env = os.environ.copy()
            env['BEEB_UTILS_DFS'] = 'acorn:'
            debug_print(f"Setting BEEB_UTILS_DFS=acorn: for dcat.pl")

            # Run dcat.pl to get catalogue
            # Use -f flag to specify the MMB file path
            cmd = ['perl', 'dcat.pl', '-f', mmb_path]
            debug_print(f"Running dcat command: {' '.join(cmd)}")

            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                cwd=os.getcwd(),
                env=env,
                check=True
            )

            debug_print(f"dcat.pl raw stdout: '{result.stdout}'")
            debug_print(f"dcat.pl raw stderr: '{result.stderr}'")

            # Parse the output to extract disk information
            disks = self._parse_dcat_output(result.stdout)
            debug_print(f"Found {len(disks)} disks in MMB: {mmb_path}")

            for disk in disks:
                debug_print(f"  Slot {disk['slot']}: '{disk['name']}' ({disk['status']})")

            return disks

        except subprocess.CalledProcessError as e:
            logger.error(f"dcat.pl failed for {mmb_path}:")
            logger.error(f"Return code: {e.returncode}")
            logger.error(f"Stdout: {e.stdout}")
            logger.error(f"Stderr: {e.stderr}")
            raise RuntimeError(f"Failed to get MMB catalogue: {e}")

    def _parse_dcat_output(self, output: str) -> List[Dict[str, Any]]:
        """
        Parse the output from dcat.pl to extract disk information.

        Args:
            output: Raw output from dcat.pl

        Returns:
            List of disk information dictionaries
        """
        disks = []
        lines = output.strip().split('\n')

        for line in lines:
            line = line.strip()
            if not line:
                continue

            # Format: "NN: Name" or "NNN: Name (L)" for locked disks
            # Examples: "  0: mmcmenu", "498: Utilities1 (L)", "500: TYBMNU"
            match = re.match(r'^(\d+):\s+(.+?)(?:\s*\(L\))?\s*$', line)
            if match:
                slot = int(match.group(1))
                name = match.group(2).strip()

                # Determine status based on whether it's locked
                status = "ReadWrite"  # Default
                if '(L)' in line:
                    status = "ReadOnly"

                disks.append({
                    'slot': slot,
                    'name': name,
                    'status': status
                })

        return disks

    def extract_ssd_from_mmb(self, mmb_path: str, slot: int, output_path: str) -> bool:
        """
        Extract a single SSD from MMB using dget_ssd.pl.

        Args:
            mmb_path: Path to the MMB file
            slot: Slot number of the disk to extract
            output_path: Path where to save the extracted SSD

        Returns:
            True if extraction successful
        """
        debug_print(f"Extracting SSD from slot {slot} in {mmb_path} to {output_path}")

        try:
            # Set BEEB_UTILS_DFS environment variable to ensure ACORN format
            env = os.environ.copy()
            env['BEEB_UTILS_DFS'] = 'acorn:'

            # Run dget_ssd.pl to extract SSD
            # Use -f flag to specify the MMB file path
            cmd = ['perl', 'dget_ssd.pl', '-f', mmb_path, str(slot), output_path]
            debug_print(f"Running dget_ssd command: {' '.join(cmd)}")

            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                cwd=os.getcwd(),
                env=env,
                check=True
            )

            debug_print(f"dget_ssd.pl stdout: {result.stdout}")
            if result.stderr:
                debug_print(f"dget_ssd.pl stderr: {result.stderr}")

            # Verify the SSD file was created
            if not os.path.exists(output_path):
                raise RuntimeError(f"dget_ssd.pl did not create SSD file: {output_path}")

            file_size = os.path.getsize(output_path)
            logger.info(f"Successfully extracted SSD from slot {slot} ({file_size} bytes)")
            return True

        except subprocess.CalledProcessError as e:
            logger.warning(f"dget_ssd.pl failed for slot {slot} in {mmb_path} (unsupported format?)")
            logger.debug(f"Return code: {e.returncode}")
            logger.debug(f"Stdout: {e.stdout}")
            logger.debug(f"Stderr: {e.stderr}")
            # Clean up partial file if created
            if os.path.exists(output_path):
                os.remove(output_path)
            raise RuntimeError(f"Failed to extract SSD from MMB slot {slot}: {e}")

    def process_mmb_file(self, mmb_path: str, output_csv: str = "roo_myinfo.csv") -> Dict[str, int]:
        """
        Process all disks in an MMB file.

        Args:
            mmb_path: Path to the MMB file
            output_csv: Path to output CSV file

        Returns:
            Dictionary with processing results
        """
        mmb_file = Path(mmb_path)

        if not mmb_file.exists():
            raise FileNotFoundError(f"MMB file not found: {mmb_path}")

        logger.info(f"Processing MMB file: {mmb_file.name}")
        debug_print(f"Full path: {mmb_file.absolute()}")

        # Ensure CSV file exists with headers
        from kilo_file_utils import CSVWriter
        csv_writer = CSVWriter(output_csv)
        csv_writer.ensure_csv_exists(output_csv)

        # Get catalogue of disks in MMB
        disks = self.get_mmb_catalogue(str(mmb_file))

        if not disks:
            logger.warning(f"No disks found in MMB: {mmb_file.name}")
            return {}

        results = {}
        total_files = 0

        # Process each valid disk in the MMB
        for disk in disks:
            slot = disk['slot']
            disk_name = disk['name']
            status = disk['status']

            # Skip unformatted or invalid disks
            if status in ['Unformatted', 'Invalid']:
                logger.info(f"Skipping slot {slot}: {disk_name} ({status})")
                results[f"slot_{slot}_{disk_name}"] = 0
                continue

            try:
                # Create safe SSD filename (sanitize disk name for filesystem)
                safe_disk_name = "".join(c for c in disk_name if c.isalnum() or c in ('_', '-')).strip()
                if not safe_disk_name:
                    safe_disk_name = f"disk_{slot}"
                ssd_filename = f"mmb_slot_{slot}_{safe_disk_name}.ssd"
                ssd_path = ssd_filename

                # Extract SSD from MMB
                self.extract_ssd_from_mmb(str(mmb_file), slot, ssd_path)

                # Process the extracted SSD using the main SSD processor
                from kilo_ssd_processor import SSDProcessor
                ssd_processor = SSDProcessor()
                file_count = ssd_processor.process_single_ssd(ssd_path, output_csv)

                # Update results with MMB context
                results[f"slot_{slot}_{disk_name}"] = file_count
                total_files += file_count

            except Exception as e:
                logger.error(f"Failed to process slot {slot} ({disk_name}): {e}")
                results[f"slot_{slot}_{disk_name}"] = 0
            finally:
                # Clean up extracted SSD file
                try:
                    if os.path.exists(ssd_path):
                        os.remove(ssd_path)
                        debug_print(f"Cleaned up extracted SSD: {ssd_path}")
                except Exception as e:
                    logger.warning(f"Failed to cleanup extracted SSD {ssd_path}: {e}")

        successful_disks = len([r for r in results.values() if r > 0])
        total_disks = len(results)
        logger.info(f"Processed MMB {mmb_file.name}: {successful_disks}/{total_disks} disks successful, {total_files} total files")
        return results

def main():
    """Main function for command-line usage."""
    if len(sys.argv) < 2:
        print("Usage: python kilo_mmb_processor.py <mmb_file> [output_csv]")
        print("Example: python kilo_mmb_processor.py data/BEEB.MMB mmb_output.csv")
        sys.exit(1)

    mmb_path = sys.argv[1]
    output_csv = sys.argv[2] if len(sys.argv) > 2 else "roo_myinfo.csv"

    # Validate MMB file exists
    if not os.path.exists(mmb_path):
        print(f"Error: MMB file does not exist: {mmb_path}")
        sys.exit(1)

    try:
        processor = MMBProcessor()
        results = processor.process_mmb_file(mmb_path, output_csv)

        print(f"\nMMB Processing complete!")
        print(f"Output written to: {output_csv}")
        print(f"Results: {results}")

        # Verify CSV file was created
        if os.path.exists(output_csv):
            csv_size = os.path.getsize(output_csv)
            print(f"CSV file created successfully ({csv_size} bytes)")
        else:
            print(f"Warning: CSV file was not created: {output_csv}")

    except Exception as e:
        logger.error(f"MMB processing failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()