#!/usr/bin/perl

use strict;
use warnings;

# BBC File Scanner
# Scans MMB, SSD, DSD, and regular files, extracting metadata and optionally performing
# magic detection to identify file types based on content patterns.
#
# Usage: perl scan_files.pl [--magic] <file_or_directory> output.csv
#
# Supported file types:
#   - .mmb  : Multi-volume disk images (includes disk titles in output path)
#   - .ssd  : Single-sided disk images
#   - .dsd  : Double-sided disk images
#   - Regular files with .inf companion files
#
# Magic detection (--magic flag):
#   - Reads patterns from MAGIC_SOURCE.ASM
#   - Identifies file types based on exec/load addresses and content patterns
#   - Skips content-based checks for files < 255 bytes (uses metadata only)
#   - &FF entries act as catch-all defaults based on exec address
#
# Output CSV columns:
#   fullpath, exe, length, crc, load_address, magicexe, magicload, magictext
#
# Copyright (C) 2026 RG

use FindBin;
use File::Spec;
use File::Find;

use Getopt::Long;

my $enable_magic = 0;
GetOptions('magic' => \$enable_magic) or die "Usage: perl scan_files.pl [--magic] <file_or_directory> output.csv\n";

die "Usage: perl scan_files.pl [--magic] <file_or_directory> output.csv\n" if @ARGV != 2;

my ($scan_dir, $output_csv) = @ARGV;

# Convert to absolute path for consistent handling
$scan_dir = File::Spec->rel2abs($scan_dir);

# Validate arguments
die "Error: '$scan_dir' does not exist\n" unless -e $scan_dir;

# Add BeebUtils to the library path
# Uses: tools/BeebUtils.pm - BBC file format utilities (MMB/SSD/DSD parsing, CRC calculation, etc.)
use lib './tools';
use BeebUtils;

# Global variables
my $total_files = 0;
my $matched_count = 0;
my @mmb_files = ();
my @ssd_files = ();
my @dsd_files = ();
my @regular_files = ();
my @magic_patterns = ();

# Suppress warnings from BeebUtils when processing corrupted entries
$SIG{__WARN__} = sub {
    my $warning = shift;
    return if $warning =~ /substr outside of string at tools\/BeebUtils\.pm line 847/;
    return if $warning =~ /Use of uninitialized value in subtraction \(-\) at tools\/BeebUtils\.pm line 800/;
    warn $warning;
};

# Main execution
sub main {
    my $csv_fh = open_output_file($output_csv);
    write_csv_header($csv_fh);
    
    load_magic_patterns() if $enable_magic;
    
    if (-f $scan_dir) {
        # Process single file
        process_single_file_input($scan_dir);
        process_files($csv_fh, $scan_dir);
    } else {
        # Process directory
        scan_directory($scan_dir);
        process_files($csv_fh, $scan_dir);
    }
    
    close $csv_fh;
    print_summary($output_csv);
}

# Open output file for writing
sub open_output_file {
    my ($output_csv) = @_;
    open my $fh, ">", $output_csv or die "Cannot open $output_csv: $!";
    return $fh;
}

# Write CSV header
sub write_csv_header {
    my ($csv_fh) = @_;
    if ($enable_magic) {
        print $csv_fh "fullpath,exe,length,crc,load_address,magicexe,magicload,magictext\n";
    } else {
        print $csv_fh "fullpath,exe,length,crc,load_address\n";
    }
}

# Scan directory and categorize files
sub scan_directory {
    my ($dir) = @_;
    find(sub { categorize_file($File::Find::name); }, $dir);
    print "Found " . scalar(@mmb_files + @ssd_files + @dsd_files + @regular_files) . " files total\n";
}

# Categorize found files
sub categorize_file {
    my ($file) = @_;
    
    $file = File::Spec->rel2abs($file) unless File::Spec->file_name_is_absolute($file);
    
    return unless -f $file;
    return if $file eq '.' or $file eq '..';
    
    $total_files++;
    
    if ($file =~ /\.mmb$/i) {
        push @mmb_files, $file;
        print "Found MMB file: $file\n";
    } elsif ($file =~ /\.ssd$/i) {
        push @ssd_files, $file;
        print "Found SSD file: $file\n";
    } elsif ($file =~ /\.dsd$/i) {
        push @dsd_files, $file;
        print "Found DSD file: $file\n";
    } elsif ($file =~ /\.inf$/i) {
        print "Found .inf file: $file\n";
    } else {
        push @regular_files, $file;
        print "Found regular file: $file\n";
    }
}

# Process single file input
sub process_single_file_input {
    my ($file_path) = @_;
    
    $file_path = File::Spec->rel2abs($file_path) unless File::Spec->file_name_is_absolute($file_path);
    
    print "Processing single file: $file_path\n";
    categorize_file($file_path);
    
    # Update scan_dir to be the directory containing the file for relative path calculations
    my ($volume, $directories, $filename) = File::Spec->splitpath($file_path);
    $scan_dir = File::Spec->catpath($volume, $directories, '');
}

# Process all categorized files
sub process_files {
    my ($csv_fh, $scan_dir) = @_;
    
    print "\n=== Processing MMB Files ===\n";
    process_mmb_files($csv_fh, $scan_dir);
    
    print "\n=== Processing SSD Files ===\n";
    process_ssd_files($csv_fh, $scan_dir);
    
    print "\n=== Processing DSD Files ===\n";
    process_dsd_files($csv_fh, $scan_dir);
    
    print "\n=== Processing Regular Files ===\n";
    process_regular_files($csv_fh, $scan_dir);
}

# Load magic patterns from Magic_source.asm
sub load_magic_patterns {
    my $magic_file = 'MAGIC_SOURCE.ASM';
  
    unless (-f $magic_file) {
        warn "Warning: Magic source file '$magic_file' not found. Magic detection disabled.\n";
        return;
    }
    
    open my $fh, '<', $magic_file or do {
        warn "Warning: Cannot open magic source file '$magic_file': $!. Magic detection disabled.\n";
        return;
    };
    
    @magic_patterns = ();
    my $in_magic_section = 0;
    
    while (my $line = <$fh>) {
        chomp $line;
        
        $in_magic_section = 1 if $line =~ /\.MagicData/;
        last if $in_magic_section && $line =~ /^\.end$/;
        
        next unless $in_magic_section;
        next if $line =~ /^\s*\\|^\.MagicData|^\.end$/;
        
        # Parse EQUS lines
        if ($line =~ /EQUS\s+(.*)/) {
            my $data_str = $1;
            my $pattern = parse_equs_line($data_str);
            push @magic_patterns, $pattern if $pattern;
        }
    }
    
    close $fh;
    print "Loaded " . scalar(@magic_patterns) . " magic patterns from $magic_file\n";
}

# Parse EQUS line into pattern structure
sub parse_equs_line {
    my ($data_str) = @_;
    
    my @tokens = split /,/, $data_str;
    return unless @tokens >= 4;
    
    my $type = shift @tokens;
    $type =~ s/^\s+|\s+$//g;
    $type = parse_hex($type);
    
    my $pattern = {
        type => $type,
        exec => 0,
        load => 0,
        ident => ''
    };
    
    # Parse based on type
    if ($type == 1) { # Offset, nobytes, exec, load, ident
        $pattern->{offset} = parse_hex(shift @tokens);
        $pattern->{nobytes} = parse_hex(shift @tokens);
        $pattern->{bytes} = [];
        for (1..$pattern->{nobytes}) {
            last unless @tokens;
            push @{$pattern->{bytes}}, parse_hex(shift @tokens);
        }
        
        # Skip one token after bytes (seems to be needed for some patterns)
        if (@tokens > 4) {
            my $skip_token = parse_hex(shift @tokens);
        }
        
        # Parse 16-bit exec and load values (little-endian)
        if (@tokens >= 4) {
            my $exec_lo = parse_hex(shift @tokens);
            my $exec_hi = parse_hex(shift @tokens);
            my $load_lo = parse_hex(shift @tokens);
            my $load_hi = parse_hex(shift @tokens);
            $pattern->{exec} = $exec_lo + ($exec_hi << 8);
            $pattern->{load} = $load_lo + ($load_hi << 8);
        }
    } elsif ($type == 2) { # Startrange, Endrange, minvalue, maxvalue, exec, load, ident
        $pattern->{startrange} = parse_hex(shift @tokens);
        $pattern->{endrange} = parse_hex(shift @tokens);
        $pattern->{minvalue} = parse_hex(shift @tokens);
        $pattern->{maxvalue} = parse_hex(shift @tokens);
        
        # Parse 16-bit exec and load values (little-endian) for Type 2
        if (@tokens >= 2) {
            my $exec_lo = parse_hex(shift @tokens);
            my $exec_hi = parse_hex(shift @tokens);
            my $load_lo = parse_hex(shift @tokens);
            my $load_hi = parse_hex(shift @tokens) if @tokens;
            
            $pattern->{exec} = $exec_lo + ($exec_hi << 8);
            $pattern->{load} = defined $load_hi ? $load_lo + ($load_hi << 8) : $load_lo;
            $pattern->{parsed_exec_load} = 1;  # Set flag to prevent general parsing
        }
    } elsif ($type == 3) { # loadadd, exec, load, ident
        $pattern->{loadadd} = parse_hex(shift @tokens) + (parse_hex(shift @tokens) << 8);
        $pattern->{exec} = parse_hex(shift @tokens) + (parse_hex(shift @tokens) << 8);
        $pattern->{load} = parse_hex(shift @tokens) + (parse_hex(shift @tokens) << 8);
        # Skip general exec/load parsing for Type 3 since it's already handled
        $pattern->{parsed_exec_load} = 1;
    } elsif ($type == 4) { # exec, exec, load, ident
        $pattern->{exe_check_lo} = parse_hex(shift @tokens);
        $pattern->{exe_check_hi} = parse_hex(shift @tokens);
        $pattern->{load_lo} = parse_hex(shift @tokens);
        $pattern->{load_hi} = parse_hex(shift @tokens);
        $pattern->{exec} = $pattern->{exe_check_lo} + ($pattern->{exe_check_hi} << 8);
        $pattern->{load} = $pattern->{load_lo} + ($pattern->{load_hi} << 8);
        $pattern->{parsed_exec_load} = 1;
    } elsif ($type == 5) { # no of high byte pairs, (high,count or higher), exec, load, ident
        $pattern->{pairs} = parse_hex(shift @tokens);
        $pattern->{pair_data} = [];
        for (1..$pattern->{pairs}) {
            push @{$pattern->{pair_data}}, [parse_hex(shift @tokens), parse_hex(shift @tokens)];
        }
        
        # Parse exec and load values (16-bit little-endian for exec)
        if (@tokens >= 2) {
            my $exec_lo = parse_hex(shift @tokens);
            my $exec_hi = parse_hex(shift @tokens);
            $pattern->{exec} = $exec_lo + ($exec_hi << 8);
            
            # Parse load - could be 16-bit or single byte
            if (@tokens >= 2) {
                my $load_lo = parse_hex(shift @tokens);
                my $load_hi = parse_hex(shift @tokens);
                $pattern->{load} = $load_lo + ($load_hi << 8);
            } elsif (@tokens >= 1) {
                $pattern->{load} = parse_hex(shift @tokens);
            }
            
            $pattern->{parsed_exec_load} = 1;
        }
    } elsif ($type == 6) { # offset, nobytes, check bytes, exec, load, ident
        $pattern->{offset} = parse_hex(shift @tokens);
        $pattern->{nobytes} = parse_hex(shift @tokens);
        
        $pattern->{check_bytes} = [];
        
        # Read check_bytes - stop when we hit a string (ident) or have enough
        for (1..$pattern->{nobytes}) {
            last unless @tokens;
            my $token = shift @tokens;
            if ($token =~ /^"(.*)"$/) {
                unshift @tokens, $token;  # Put string back - it's the ident
                last;
            } else {
                push @{$pattern->{check_bytes}}, parse_hex($token);
            }
        }
        
        # Collect all remaining numeric tokens for exec/load
        my @exec_load_tokens;
        while (@tokens) {
            my $token = $tokens[0];
            if ($token =~ /^&[0-9A-Fa-f]+$/ || $token =~ /^\d+$/) {
                push @exec_load_tokens, shift @tokens;
            } else {
                last;  # Stop at non-numeric token (ident string)
            }
        }
        
        # Parse exec and load values (16-bit little-endian)
        # Need at least 2 (exec), preferably 4 (exec + load)
        if (@exec_load_tokens >= 2) {
            my $exec_lo = parse_hex(shift @exec_load_tokens);
            my $exec_hi = parse_hex(shift @exec_load_tokens);
            $pattern->{exec} = $exec_lo + ($exec_hi << 8);
            
            # Parse load if we have at least 2 more tokens
            if (@exec_load_tokens >= 2) {
                my $load_lo = parse_hex(shift @exec_load_tokens);
                my $load_hi = parse_hex(shift @exec_load_tokens);
                $pattern->{load} = $load_lo + ($load_hi << 8);
            } elsif (@exec_load_tokens >= 1) {
                # Single byte load
                $pattern->{load} = parse_hex(shift @exec_load_tokens);
            }
            $pattern->{parsed_exec_load} = 1;
        }
    } elsif ($type == 7) { # count, no entries, bytes, exec, load, ident
        $pattern->{count} = parse_hex(shift @tokens);
        $pattern->{no_entries} = parse_hex(shift @tokens);
        $pattern->{entries} = [];
        for (1..$pattern->{no_entries}) {
            my $entry = shift @tokens;
            $entry =~ s/^'|\s*$//g;
            push @{$pattern->{entries}}, ord($entry) if $entry ne '';
        }
        
        # Parse exec and load values (16-bit little-endian)
        if (@tokens >= 4) {
            my $exec_lo = parse_hex(shift @tokens);
            my $exec_hi = parse_hex(shift @tokens);
            my $load_lo = parse_hex(shift @tokens);
            my $load_hi = parse_hex(shift @tokens);
            $pattern->{exec} = $exec_lo + ($exec_hi << 8);
            $pattern->{load} = $load_lo + ($load_hi << 8);
            $pattern->{parsed_exec_load} = 1;
        }
    } elsif ($type == 8) { # length, exec, load, ident
        $pattern->{length} = parse_hex(shift @tokens);
        $pattern->{length_hi} = parse_hex(shift @tokens);
        
        # Parse exec and load values (16-bit little-endian)
        if (@tokens >= 4) {
            my $exec_lo = parse_hex(shift @tokens);
            my $exec_hi = parse_hex(shift @tokens);
            my $load_lo = parse_hex(shift @tokens);
            my $load_hi = parse_hex(shift @tokens);
            $pattern->{exec} = $exec_lo + ($exec_hi << 8);
            $pattern->{load} = $load_lo + ($load_hi << 8);
            $pattern->{parsed_exec_load} = 1;
        }
    } elsif ($type == 9) { # number of bytes to match, exec, load, ident
        $pattern->{match_bytes} = [];
        my $match_count = parse_hex(shift @tokens);
        my @original_tokens = @tokens;  # Keep for debugging
        # Collect all string data for Type 9
        my @string_chars = ();
        
        # Process tokens until we have enough characters or hit the identifier
        while (@tokens && scalar(@string_chars) < $match_count) {
            my $token = shift @tokens;
            
            # If we hit an identifier (quoted string), we're done with string chars
            last if $token =~ /^".*"$/ && scalar(@string_chars) > 0;
            
            # If it's a string like "<>&E00", extract individual characters
            if ($token =~ /^"(.*)"$/) {
                my $string = $1;
                
                # Add characters to the array
                for my $i (0..length($string)-1) {
                    last if scalar(@string_chars) >= $match_count;
                    push @string_chars, ord(substr($string, $i, 1));
                }
            } else {
                # Regular number/character
                push @string_chars, parse_hex($token);
            }
        }
        
        $pattern->{match_bytes} = \@string_chars;
        
        # Parse exec and load values (16-bit little-endian)
        if (@tokens >= 4) {
            my $exec_lo = parse_hex(shift @tokens);
            my $exec_hi = parse_hex(shift @tokens);
            my $load_lo = parse_hex(shift @tokens);
            my $load_hi = parse_hex(shift @tokens);
            $pattern->{exec} = $exec_lo + ($exec_hi << 8);
            $pattern->{load} = $load_lo + ($load_hi << 8);
            $pattern->{parsed_exec_load} = 1;
        }
    } elsif ($type == 10) { # load, offset from end, exec, load, ident
        $pattern->{load_check} = parse_hex(shift @tokens);
        $pattern->{load_check_hi} = parse_hex(shift @tokens);
        $pattern->{offset_end} = parse_hex(shift @tokens);
    } elsif ($type == 0xFF) { # Direct exec/load assignment: exec_lo, exec_hi, load_lo, load_hi, ident
        if (@tokens >= 4) {
            my $val1 = parse_hex(shift @tokens);
            my $val2 = parse_hex(shift @tokens);
            my $val3 = parse_hex(shift @tokens);
            my $val4 = parse_hex(shift @tokens);
            $pattern->{exec} = $val1 + ($val2 << 8);
            $pattern->{load} = $val3 + ($val4 << 8);
            $pattern->{parsed_exec_load} = 1;
        }
    }
    
    # Extract exec, load, ident from remaining tokens (skip for types that already handle these)
    while (@tokens) {
        my $token = shift @tokens;
        $token =~ s/^\s+|\s+$//g;
        
        if ($token =~ /^&[0-9A-Fa-f]+$/ || $token =~ /^\d+$/) {
            my $value = parse_hex($token);
            # Skip numeric tokens for patterns that already parsed exec/load values
            next if $pattern->{parsed_exec_load};
            
            if (!defined $pattern->{exec}) {
                $pattern->{exec} = $value;
            } elsif (!defined $pattern->{load}) {
                $pattern->{load} = $value;
            }
        } elsif ($token =~ /^"(.*)"$/) {
            $pattern->{ident} = $1;
        } elsif ($token =~ /^'(.*)'$/) {
            $pattern->{ident} = $1;
        }
    }
    

    
    return $pattern;
}

# Parse hex or decimal value
sub parse_hex {
    my ($value) = @_;
    $value =~ s/^\s+|\s+$//g;
    
    if ($value =~ /^&[0-9A-Fa-f]+$/) {
        return hex(substr($value, 1));  # Remove & and convert
    } elsif ($value =~ /^\d+$/) {
        return int($value);
    } elsif ($value =~ /^'(.*)'$/) {
        return ord($1);
    } else {
        warn "Warning: Cannot parse value '$value' as number\n";
        return 0;
    }
}

# Perform magic detection on file data
sub detect_magic {
    my ($file_data, $current_exe, $current_load) = @_;
    
    return (0, 0, 'no match #1') unless @magic_patterns && defined $file_data && length($file_data) > 0;
    
    my $file_size = length($file_data);
    my $skip_content_checks = ($file_size < 255);
    
    my $first_page = substr($file_data, 0, 256);
    
    # Create byte frequency table for statistics
    my @byte_counts = (0) x 256;
    for my $i (0..length($first_page)-1) {
        my $byte = ord(substr($first_page, $i, 1));
        $byte_counts[$byte]++;
    }
    
    my $pattern_count = 0;
    my @ff_patterns;
    
    foreach my $pattern (@magic_patterns) {
        $pattern_count++;
        my $matched = 0;
        
        # Collect &FF patterns for later (they act as catch-all)
        if ($pattern->{type} == 0xFF) {
            push @ff_patterns, $pattern;
            next;
        }
        
        # Skip content-dependent types for files < 255 bytes
        next if $skip_content_checks && grep { $pattern->{type} == $_ } (1, 2, 5, 6, 7, 9);
        
        if ($pattern->{type} == 1) { # Offset byte matching
            $matched = check_type1($pattern, $first_page);
        } elsif ($pattern->{type} == 2) { # Byte range and count
            $matched = check_type2($pattern, \@byte_counts, $file_size);
        } elsif ($pattern->{type} == 3) { # Load address matching
            $matched = check_type3($pattern, $current_load);
        } elsif ($pattern->{type} == 4) { # Exec address matching
            $matched = check_type4($pattern, $current_exe);
        } elsif ($pattern->{type} == 5) { # High byte frequency
            $matched = check_type5($pattern, \@byte_counts);
        } elsif ($pattern->{type} == 6) { # Offset byte matching (variant)
            $matched = check_type6($pattern, $first_page);
        } elsif ($pattern->{type} == 7) { # Character frequency
            $matched = check_type7($pattern, \@byte_counts);
        } elsif ($pattern->{type} == 8) { # File size matching
            $matched = check_type8($pattern, $file_size);
        } elsif ($pattern->{type} == 9) { # String search in first page
            $matched = check_type9($pattern, $first_page);
        } elsif ($pattern->{type} == 10) { # Load + size - offset = exe check
            $matched = check_type10($pattern, $current_load, $file_size, $current_exe);
        }
        
        if ($matched) {
            my $magic_exe = $pattern->{exec};
            my $magic_load = $pattern->{load};
            return ($magic_exe, $magic_load, $pattern->{ident});
        }
    }
    
    # If no pattern matched, check &FF patterns (check current_exe against pattern exec)
    foreach my $pattern (@ff_patterns) {
        if ($pattern->{type} == 0xFF && $current_exe == $pattern->{exec}) {
            my $magic_exe = $pattern->{exec};
            my $magic_load = $pattern->{load};
            return ($magic_exe, $magic_load, $pattern->{ident});
        }
    }
    
    return (0, 0, 'no match #1');
}



# Type 1: Offset byte matching
sub check_type1 {
    my ($pattern, $first_page) = @_;
    
    if ($pattern->{ident} && $pattern->{ident} =~ /Basic/) {
        my $first_byte = ord(substr($first_page, $pattern->{offset}, 1)) if length($first_page) > $pattern->{offset};
        my $expected = $pattern->{bytes}[0];

    }
    
    return 0 if $pattern->{offset} >= length($first_page);
    return 0 if $pattern->{offset} + $pattern->{nobytes} > length($first_page);
    
    for my $i (0..$#{$pattern->{bytes}}) {
        my $expected = $pattern->{bytes}->[$i];
        my $actual = ord(substr($first_page, $pattern->{offset} + $i, 1));
        return 0 if $expected != $actual;
    }
    
    return 1;
}


sub check_type2 {
    my ($pattern, $byte_counts, $file_size) = @_;
    
    # Check if the range is valid
    return 0 if $pattern->{startrange} > $pattern->{endrange} || $pattern->{startrange} < 0 || $pattern->{endrange} < 0;
    
    # Check if each byte in the range is within the minvalue and maxvalue bounds
    for my $i ($pattern->{startrange}..$pattern->{endrange}) {
        return 0 if $byte_counts->[$i] < $pattern->{minvalue} || $byte_counts->[$i] > $pattern->{maxvalue};
    }
    
    return 1;
}

# Type 3: Load address matching
sub check_type3 {
    my ($pattern, $current_load) = @_;
    return $current_load == $pattern->{loadadd};
}

# Type 4: Exec address matching
sub check_type4 {
    my ($pattern, $current_exe) = @_;
    my $pattern_exec = ($pattern->{exe_check_hi} << 8) + $pattern->{exe_check_lo};
    return $current_exe == $pattern_exec;
}

# Type 5: High byte frequency
sub check_type5 {
    my ($pattern, $byte_counts) = @_;
    
    foreach my $pair (@{$pattern->{pair_data}}) {
        my ($high_byte, $min_count) = @$pair;
        if ($byte_counts->[$high_byte] < $min_count) {
            return 0;
        }
    }
    
    return 1;
}

# Type 6: Offset byte matching variant
# Logic (from magic.asm):
# 1. First byte at offset = position in file to read from
# 2. Second byte (nobytes - 1) = number of bytes to compare
# 3. Compare those bytes from file to check_bytes
sub check_type6 {
    my ($pattern, $first_page) = @_;
    
    my $offset = $pattern->{offset};
    return 0 if $offset >= length($first_page);
    
    # Step 1: Read byte at offset - this is the position in file to start checking
    my $start_pos = ord(substr($first_page, $offset, 1));
    
    # Step 2: Use nobytes - 1 from pattern as the count (as per user's description)
    my $byte_count = $pattern->{nobytes} - 1;
    
    # Handle nobytes = 0 case (compare 0 bytes = always match?)
    $byte_count = 0 if $byte_count < 0;
    
    # Step 3: Compare byte_count bytes starting from start_pos
    return 0 if $start_pos >= length($first_page);
    return 0 if $start_pos + $byte_count > length($first_page);
    
    for my $i (0..$byte_count - 1) {
        last if $i >= @{$pattern->{check_bytes}};
        my $expected = $pattern->{check_bytes}->[$i];
        my $actual = ord(substr($first_page, $start_pos + $i, 1));
        return 0 if $expected != $actual;
    }
    
    return 1;
}

# Type 7: Character frequency
sub check_type7 {
    my ($pattern, $byte_counts) = @_;
    
    my $total_count = 0;
    foreach my $char (@{$pattern->{entries}}) {
        $total_count += $byte_counts->[$char];
    }
    
    return $total_count >= $pattern->{count};
}

# Type 8: File size matching
sub check_type8 {
    my ($pattern, $file_size) = @_;
    my $expected_size = ($pattern->{length_hi} << 8) + $pattern->{length};
    return $file_size == $expected_size;
}

# Type 9: String search in first page
sub check_type9 {
    my ($pattern, $first_page) = @_;
    
    my $search_str = '';
    foreach my $byte (@{$pattern->{match_bytes}}) {
        $search_str .= chr($byte);
    }
    
    return index($first_page, $search_str) >= 0;
}

# Type 10: Load + size - offset = exe check
sub check_type10 {
    my ($pattern, $current_load, $file_size, $current_exe) = @_;
    
    return 0 unless $current_load == ($pattern->{load_check_hi} << 8) + $pattern->{load_check};
    
    my $calculated_exe = $current_load + $file_size - $pattern->{offset_end};
    return $current_exe == $calculated_exe;
}

# Clean BBC filename according to BeebUtils logic
sub clean_bbc_filename {
    my ($filename) = @_;
    
    # Remove null terminators and everything after
    $filename =~ s/\0.*$//;
    
    # Strip high bits from entire string first
    my $stripped = '';
    for my $i (0..length($filename)-1) {
        my $ord = ord(substr($filename, $i, 1));
        $stripped .= chr($ord & 127);
    }
    $filename = $stripped;
    
    # Remove leading/trailing spaces and non-printable characters
    $filename =~ s/^\s+|\s+$//g;
    $filename =~ s/[^\x20-\x7E]//g;
    
    return $filename;
}

# Calculate CRC with error handling
sub calculate_crc {
    my ($file_data) = @_;
    
    my $crc;
    eval {
        $crc = BeebUtils::CalcCrc(\$file_data);
    };
    
    return $@ ? undef : $crc;
}

# Format path for CSV output
sub format_output_path {
    my ($path, $scan_dir) = @_;
    my $relative_path = File::Spec->abs2rel($path, $scan_dir);
    $relative_path =~ s|/|\\|g;
    return $relative_path;
}

# Write CSV record
sub write_csv_record {
    my ($csv_fh, $path, $exec_addr, $size, $crc, $load_addr, $file_data) = @_;
    
    my ($magic_exe, $magic_load, $magic_text);
    if ($enable_magic) {
        ($magic_exe, $magic_load, $magic_text) = detect_magic($file_data, $exec_addr, $load_addr);
        $magic_exe //= '';
        $magic_load //= '';
        $magic_text //= '';
    }
    
    if ($enable_magic) {
        print $csv_fh "$path,$exec_addr,$size,$crc,$load_addr,$magic_exe,$magic_load,$magic_text\n";
    } else {
        print $csv_fh "$path,$exec_addr,$size,$crc,$load_addr\n";
    }
    $matched_count++;
}

# Process MMB files
sub process_mmb_files {
    my ($csv_fh, $scan_dir) = @_;
    
    return unless @mmb_files;
    
    foreach my $mmb_file (@mmb_files) {
        print "\nProcessing MMB file: $mmb_file\n";
        process_single_mmb($mmb_file, $csv_fh, $scan_dir);
    }
}

# Process single MMB file
sub process_single_mmb {
    my ($mmb_file, $csv_fh, $scan_dir) = @_;
    
    $BeebUtils::BBC_FILE = $mmb_file;
    
    my $disktable = BeebUtils::LoadDiskTable();
    my %disks = BeebUtils::load_dcat(\$disktable);
    
    my ($disk_count, $file_count) = (0, 0);
    
    foreach my $disk_num (sort { $a <=> $b } keys %disks) {
        my $disk_info = $disks{$disk_num};
        
        next unless $disk_info->{ValidDisk} && $disk_info->{Formatted};
        
        my $ssd_image = BeebUtils::read_ssd($disk_num);
        my %files = BeebUtils::read_cat(\$ssd_image);
        
        my $disk_title = $files{""}{title} || '';
        $disk_title =~ s/\0.*$//;
        $disk_title =~ s/[^\x20-\x7E]//g;
        $disk_title =~ s/^\s+|\s+$//g;
        
        delete $files{""};
        
        $file_count += process_mmb_disk_files($mmb_file, $disk_num, \%files, $ssd_image, $csv_fh, $scan_dir, $disk_title);
        $disk_count++;
    }
    
    print "Processed MMB: $mmb_file (disks: $disk_count, files: $file_count)\n";
}

# Process files from MMB disk
sub process_mmb_disk_files {
    my ($mmb_file, $disk_num, $files, $ssd_image, $csv_fh, $scan_dir, $disk_title) = @_;
    
    my $file_count = 0;
    
    foreach my $catalog_entry_num (sort keys %$files) {
        my $file_info = $files->{$catalog_entry_num};
        my $file_name = $file_info->{name};
        
        next unless $file_name && $file_name !~ /^\s*$/;
        
        my $file_data = extract_file_safely(\$ssd_image, $file_name, $files);
        next unless $file_data;
        
        my $crc = calculate_crc($file_data);
        next unless defined $crc;
        
        my $clean_name = clean_bbc_filename($file_name);
        my $disk_num_formatted = sprintf("%02d", $disk_num);
        my $relative_mmb_path = format_output_path($mmb_file, $scan_dir);
        $relative_mmb_path =~ s/\.(mmb|MMB)$//i;
        
        my $disk_title_path = $disk_title ? "$disk_title\\" : '';
        my $output_path = "$relative_mmb_path\\$disk_num_formatted\\$disk_title_path$clean_name";
        
        write_csv_record($csv_fh, $output_path, $file_info->{exec}, 
                         $file_info->{size}, $crc, $file_info->{load}, $file_data);
        $file_count++;
    }
    
    return $file_count;
}

# Process SSD files
sub process_ssd_files {
    my ($csv_fh, $scan_dir) = @_;
    
    return unless @ssd_files;
    
    foreach my $ssd_file (@ssd_files) {
        print "Processing SSD file: $ssd_file\n";
        process_single_ssd($ssd_file, $csv_fh, $scan_dir);
    }
}

# Process single SSD file
sub process_single_ssd {
    my ($ssd_file, $csv_fh, $scan_dir) = @_;
    
    my $ssd_image = read_ssd_file($ssd_file);
    return unless $ssd_image;
    
    my %files = BeebUtils::read_cat(\$ssd_image);
    delete $files{""};
    
    my $file_count = 0;
    
    foreach my $catalog_entry_num (sort keys %files) {
        my $file_info = $files{$catalog_entry_num};
        my $file_name = $file_info->{name};
        
        next unless $file_name && $file_name !~ /^\s*$/;
        
        my $file_data = extract_file_safely(\$ssd_image, $file_name, \%files);
        next unless $file_data;
        
        my $crc = calculate_crc($file_data);
        next unless defined $crc;
        
        my $clean_name = clean_bbc_filename($file_name);
        my $relative_path = format_output_path($ssd_file, $scan_dir);
        $relative_path =~ s/\.ssd$//i;
        
        my $output_path = "$relative_path\\$clean_name";
        
        write_csv_record($csv_fh, $output_path, $file_info->{exec}, 
                         $file_info->{size}, $crc, $file_info->{load}, $file_data);
        $file_count++;
    }
    
    print "Processed SSD: $ssd_file (files: $file_count)\n";
}

# Process DSD files
sub process_dsd_files {
    my ($csv_fh, $scan_dir) = @_;
    
    return unless @dsd_files;
    
    foreach my $dsd_file (@dsd_files) {
        print "Processing DSD file: $dsd_file\n";
        process_single_dsd($dsd_file, $csv_fh, $scan_dir);
    }
}

# Process single DSD file
sub process_single_dsd {
    my ($dsd_file, $csv_fh, $scan_dir) = @_;
    
    my ($ssd0, $ssd1) = split_dsd($dsd_file);
    return unless $ssd0 && $ssd1;
    
    my $relative_path = format_output_path($dsd_file, $scan_dir);
    $relative_path =~ s/\.dsd$//i;
    
    my $file_count = 0;
    
    # Process side 0
    my %files0 = BeebUtils::read_cat(\$ssd0);
    delete $files0{""};
    
    foreach my $catalog_entry_num (sort keys %files0) {
        my $file_info = $files0{$catalog_entry_num};
        my $file_name = $file_info->{name};
        
        next unless $file_name && $file_name !~ /^\s*$/;
        
        my $file_data = extract_file_safely(\$ssd0, $file_name, \%files0);
        next unless $file_data;
        
        my $crc = calculate_crc($file_data);
        next unless defined $crc;
        
        my $clean_name = clean_bbc_filename($file_name);
        my $output_path = "$relative_path\\0\\$clean_name";
        
        write_csv_record($csv_fh, $output_path, $file_info->{exec},
                         $file_info->{size}, $crc, $file_info->{load}, $file_data);
        $file_count++;
    }
    
    # Process side 1
    my %files1 = BeebUtils::read_cat(\$ssd1);
    delete $files1{""};
    
    foreach my $catalog_entry_num (sort keys %files1) {
        my $file_info = $files1{$catalog_entry_num};
        my $file_name = $file_info->{name};
        
        next unless $file_name && $file_name !~ /^\s*$/;
        
        my $file_data = extract_file_safely(\$ssd1, $file_name, \%files1);
        next unless $file_data;
        
        my $crc = calculate_crc($file_data);
        next unless defined $crc;
        
        my $clean_name = clean_bbc_filename($file_name);
        my $output_path = "$relative_path\\1\\$clean_name";
        
        write_csv_record($csv_fh, $output_path, $file_info->{exec},
                         $file_info->{size}, $crc, $file_info->{load}, $file_data);
        $file_count++;
    }
    
    print "Processed DSD: $dsd_file (files: $file_count)\n";
}

# Split DSD file into two SSD images
sub split_dsd {
    my ($dsd_file) = @_;
    
    return unless -f $dsd_file;
    
    open my $fh, '<', $dsd_file or do {
        warn "Cannot open DSD file $dsd_file: $!";
        return (undef, undef);
    };
    
    binmode $fh;
    my $dsd_data;
    read $fh, $dsd_data, -s $fh;
    close $fh;
    
    my $track_size = 256 * 10; # 10 sectors of 256 bytes each
    my $ssd_size = $track_size * 80; # 80 tracks
    
    my $ssd0 = '';
    my $ssd1 = '';
    
    # De-interleave the DSD data by track
    for my $track (0..79) {
        my $offset = $track * $track_size * 2;
        if ($offset + $track_size * 2 <= length($dsd_data)) {
            $ssd0 .= substr($dsd_data, $offset, $track_size);
            $ssd1 .= substr($dsd_data, $offset + $track_size, $track_size);
        }
    }
    
    return ($ssd0, $ssd1);
}

# Read SSD file content
sub read_ssd_file {
    my ($ssd_file) = @_;
    
    return unless -f $ssd_file;
    
    open my $fh, '<', $ssd_file or do {
        warn "Cannot open SSD file $ssd_file: $!";
        return undef;
    };
    
    binmode $fh;
    my $ssd_image;
    read $fh, $ssd_image, -s $fh;
    close $fh;
    
    return $ssd_image;
}

# Extract file safely with error handling
sub extract_file_safely {
    my ($ssd_image_ref, $file_name, $files) = @_;
    
    my $file_data;
    eval {
        $file_data = BeebUtils::ExtractFile($ssd_image_ref, $file_name, %$files);
    };
    
    return ($@ || !defined $file_data || length($file_data) == 0) ? undef : $file_data;
}

# Process regular files with .inf
sub process_regular_files {
    my ($csv_fh, $scan_dir) = @_;
    
    return unless @regular_files;
    
    foreach my $regular_file (@regular_files) {
        print "Processing regular file: $regular_file\n";
        process_single_regular_file($regular_file, $csv_fh, $scan_dir);
    }
}

# Process single regular file
sub process_single_regular_file {
    my ($file_path, $csv_fh, $scan_dir) = @_;
    
    my $inf_file = "$file_path.inf";
    return unless -f $inf_file;
    
    my ($load_addr, $exec_addr) = parse_inf_file($inf_file);
    return unless defined $load_addr && defined $exec_addr;
    
    my $file_data = read_file_content($file_path);
    return unless $file_data;
    
    my $crc = calculate_crc($file_data);
    return unless defined $crc;
    
    my $clean_path = format_output_path($file_path, $scan_dir);
    my $file_size = -s $file_path;
    
    write_csv_record($csv_fh, $clean_path, $exec_addr, $file_size, $crc, $load_addr, $file_data);
}

# Parse .inf file for load and exec addresses
sub parse_inf_file {
    my ($inf_file) = @_;
    
    open my $inf_fh, '<', $inf_file or do {
        warn "Cannot open .inf file $inf_file: $!";
        return (undef, undef);
    };
    
    my $inf_line = <$inf_fh>;
    close $inf_fh;
    
    return (undef, undef) unless $inf_line;
    
    # Try format 1: $.whatfs   007500 007500 0005F2   
    if ($inf_line =~ /^\s*\$.\S+\s+([0-9A-Fa-f]+)\s+([0-9A-Fa-f]+)/) {
        return (hex($1), hex($2));
    }
    
    # Try format 2: P.DinRen   FF1900 FF8023 000A64   
    if ($inf_line =~ /^\s*\S+\s+([0-9A-Fa-f]+)\s+([0-9A-Fa-f]+)/) {
        return (hex($1), hex($2));
    }
    
    return (undef, undef);
}

# Read file content
sub read_file_content {
    my ($file_path) = @_;
    
    open my $file_fh, '<', $file_path or do {
        warn "Cannot open file $file_path: $!";
        return undef;
    };
    
    binmode $file_fh;
    my $file_data;
    read $file_fh, $file_data, -s $file_path;
    close $file_fh;
    
    return $file_data;
}

# Print final summary
sub print_summary {
    my ($output_csv) = @_;
    
    print "\n=== Final Summary ===\n";
    print "  Total files found: $total_files\n";
    print "  Files with matching .inf: $matched_count\n";
    print "  MMB files found: " . scalar(@mmb_files) . "\n";
    print "  SSD files found: " . scalar(@ssd_files) . "\n";
    print "  DSD files found: " . scalar(@dsd_files) . "\n";
    print "  Regular files found: " . scalar(@regular_files) . "\n";
    print "  CSV written to: $output_csv\n";
}

# Initialize BeebUtils
$BeebUtils::BBC_FILE = "";

# Run main program
main();