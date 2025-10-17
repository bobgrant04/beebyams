#!/usr/bin/env python3
"""
kilo_main.py - Main entry point for Kilo utilities

This script provides a command-line interface for the Kilo utilities suite,
including SSD processing and CSV extraction functionality.
Environment: Windows 11
Author: Kilo Code
"""

import sys
import argparse
from pathlib import Path
from typing import Optional

# Import our modules
import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from kilo_logger import logger, debug_print, set_debug
from kilo_ssd_processor import SSDProcessor

class KiloMain:
    """Main application class for Kilo utilities."""

    def __init__(self):
        self.version = "1.0.0"
        self.description = "Kilo Utilities - SSD and MMB processing and CSV extraction tools"

    def create_parser(self) -> argparse.ArgumentParser:
        """Create command-line argument parser."""
        parser = argparse.ArgumentParser(
            description=self.description,
            formatter_class=argparse.RawDescriptionHelpFormatter,
            epilog="""
Examples:
  %(prog)s data/altD002b.ssd                    # Process single SSD file
  %(prog)s ./disks/                             # Process all SSD files in directory
  %(prog)s data/BEEB.mmb                        # Process all disks in MMB file
  %(prog)s -o output.csv data/altD002b.ssd     # Specify output CSV file
  %(prog)s -v data/altD002b.ssd                 # Verbose output
  %(prog)s --debug data/altD002b.ssd            # Debug output (same as DEBUG=TRUE)
            """
        )

        parser.add_argument(
            'input',
            help='SSD file, directory containing SSD files, or MMB file to process'
        )

        parser.add_argument(
            '-o', '--output',
            default='roo_myinfo.csv',
            help='Output CSV file (default: roo_myinfo.csv)'
        )

        parser.add_argument(
            '-v', '--verbose',
            action='store_true',
            help='Enable verbose output'
        )

        parser.add_argument(
            '--debug',
            action='store_true',
            help='Enable debug output (same as setting DEBUG=TRUE environment variable)'
        )

        parser.add_argument(
            '--version',
            action='version',
            version=f'%(prog)s {self.version}'
        )

        return parser

    def setup_logging(self, verbose: bool, debug: bool) -> None:
        """Setup logging based on command-line arguments."""
        if debug:
            set_debug(True)
            logger.info("Debug logging enabled")
        elif verbose:
            logger.info("Verbose logging enabled")

    def run(self, args: Optional[list] = None) -> int:
        """
        Run the main application.

        Args:
            args: Command-line arguments (uses sys.argv if None)

        Returns:
            Exit code (0 for success, 1 for error)
        """
        parser = self.create_parser()

        try:
            parsed_args = parser.parse_args(args)

            # Setup logging
            self.setup_logging(parsed_args.verbose, parsed_args.debug)

            # Validate input path
            input_path = Path(parsed_args.input)
            if not input_path.exists():
                logger.error(f"Input path does not exist: {parsed_args.input}")
                return 1

            # Process input
            logger.info(f"Kilo Utilities v{self.version}")
            logger.info(f"Processing: {parsed_args.input}")
            logger.info(f"Output CSV: {parsed_args.output}")

            try:
                processor = SSDProcessor()
                results = processor.process_input(parsed_args.input, parsed_args.output)

                # Display results
                if isinstance(results, dict):
                    total_files = sum(results.values())
                    logger.info(f"Processing complete! Extracted {total_files} files from {len(results)} SSD files")

                    if debug_print != logger.debug:  # If debug is enabled
                        for ssd_name, file_count in results.items():
                            debug_print(f"  {ssd_name}: {file_count} files")

                return 0

            except Exception as e:
                logger.error(f"Processing failed: {e}")
                if debug_print != logger.debug:  # If debug is enabled
                    import traceback
                    debug_print(f"Traceback: {traceback.format_exc()}")
                return 1

        except KeyboardInterrupt:
            logger.info("Operation cancelled by user")
            return 1

        except Exception as e:
            logger.error(f"Application error: {e}")
            return 1

def main() -> int:
    """Main entry point."""
    app = KiloMain()
    return app.run()

if __name__ == "__main__":
    sys.exit(main())