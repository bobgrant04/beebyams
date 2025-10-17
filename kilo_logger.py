#!/usr/bin/env python3
"""
kilo_logger.py - Centralized logging functionality for Kilo utilities

This module provides verbose logging and print statements controlled by DEBUG variable.
Environment: Windows 11
Author: Kilo Code
"""

import os
import sys
import logging
from typing import Optional

# DEBUG variable set to TRUE by default for verbose logging
DEBUG = os.getenv('DEBUG', 'TRUE').upper() == 'TRUE'

class KiloLogger:
    """Centralized logger for Kilo utilities with verbose output control."""

    def __init__(self, name: str = 'kilo_utils'):
        self.logger = logging.getLogger(name)
        self.debug_enabled = DEBUG

        if self.debug_enabled:
            self.logger.setLevel(logging.DEBUG)
        else:
            self.logger.setLevel(logging.INFO)

        # Remove any existing handlers to avoid duplicates
        self.logger.handlers.clear()

        # Create console handler
        handler = logging.StreamHandler(sys.stdout)
        handler.setLevel(logging.DEBUG)

        # Create formatter
        formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S'
        )
        handler.setFormatter(formatter)

        # Add handler to logger
        self.logger.addHandler(handler)

    def debug(self, message: str) -> None:
        """Log debug message if DEBUG is enabled."""
        if self.debug_enabled:
            self.logger.debug(message)

    def info(self, message: str) -> None:
        """Log info message."""
        self.logger.info(message)

    def warning(self, message: str) -> None:
        """Log warning message."""
        self.logger.warning(message)

    def error(self, message: str) -> None:
        """Log error message."""
        self.logger.error(message)

    def critical(self, message: str) -> None:
        """Log critical message."""
        self.logger.critical(message)

# Global logger instance
logger = KiloLogger()

def debug_print(message: str) -> None:
    """Print debug message if DEBUG is enabled."""
    if DEBUG:
        print(f"[DEBUG] {message}")

def verbose_print(message: str) -> None:
    """Print verbose message."""
    print(message)

def set_debug(enabled: bool) -> None:
    """Enable or disable debug logging."""
    global DEBUG
    DEBUG = enabled
    logger.debug_enabled = enabled
    debug_print(f"Debug logging {'enabled' if enabled else 'disabled'}")