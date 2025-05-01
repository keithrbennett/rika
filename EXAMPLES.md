# Rika Examples

This document provides practical examples of how to use Rika for extracting metadata and text from various file types.

## Table of Contents
- [Getting Started](#getting-started)
- [File Selection](#file-selection)
- [Output Options](#output-options)
- [Working with URLs](#working-with-urls)
- [Common Use Cases](#common-use-cases)
      - [Document Management](#document-management)
      - [Text Extraction](#text-extraction)
      - [Batch Processing](#batch-processing)
- [Advanced Usage](#advanced-usage)
      - [Integration with Other Tools](#integration-with-other-tools)
      - [Environment Variables](#environment-variables)
- [Best Practices](#best-practices)

## Getting Started

### Basic Command Structure
```bash
rika [options] <filespec>...  # Process files with optional flags
```

### Simple Examples
```bash
# Process a single file (outputs both metadata and text by default)
rika document.pdf

# Process an image file
rika image.png
```

### Preview Operations (Dry Run)
```bash
# Preview what files would be processed without actually processing them
rika -n "*.pdf"
```

## File Selection

### Working with Multiple Files
```bash
# Process all PDFs in current directory
rika "*.pdf"  # Always quote wildcards to prevent shell expansion

# Process multiple file types
rika "*.{pdf,doc,docx}"

# Process files from different directories
rika "reports/*.pdf" "drafts/*.doc"
```

### Recursive File Selection
```bash
# Search this directory and all subdirectories
rika "**/*.pdf"  

# Recursive search for multiple types
rika "**/*.{pdf,doc,png,jpg}"
```

### Special Cases
```bash
# Files with spaces in names
rika 'file with spaces.pdf'

# Using variables
rika "$HOME/documents/*.pdf"
```

## Output Options

### Control Output Content
```bash
# Default: outputs filespec banner, metadata, and text
rika document.pdf

# Metadata only (exclude text)
rika -t- document.pdf

# Text only (exclude metadata)
rika -m- document.pdf

# Disable filespec banner (for cleaner output)
rika -s- document.pdf
```

### Output Formats
```bash
# JSON format (-f j)
rika -f j document.pdf

# YAML format (-f y)
rika -f y document.pdf

# Pretty JSON format (-f J)
rika -f J document.pdf

# AwesomePrint format (-f a)
rika -f a document.pdf
```

### Combining Output Options
```bash
# Metadata only in JSON format with banner
rika -t- -f j document.pdf

# Text only in default format without banner
rika -s- -m- document.pdf

# Metadata in JSON format, text in AwesomePrint format
rika -f ja document.pdf

# Machine-readable JSON without banner (ideal for scripting)
rika -s- -f j document.pdf
```

## Working with URLs

```bash
# Process a document from a web server
rika https://example.com/docs/document.pdf

# Process an image from a web server
rika https://example.com/images/image.png
```

## Common Use Cases

### Document Management

```bash
# Extract and save metadata in JSON format
rika -t- -f j document.pdf > metadata.json

# Compare metadata of multiple documents
rika -t- -f a "*.pdf"

# Quick document inventory
rika -t- "**/*.{pdf,doc,docx}" > document_inventory.txt
```

### Text Extraction

```bash
# Extract text from a single document
rika -m- document.pdf > document.txt

# Convert multiple documents to text
rika -m- "*.pdf" > all_documents.txt

# Extract and search for specific content
rika -m- document.pdf | grep "search term"

# Extract text without the filespec banner
rika -s- -m- document.pdf > clean_text.txt
```

### Batch Processing

```bash
# Process all PDFs in a directory
rika "*.pdf" > output.txt

# Process both documents and images
rika "*.{pdf,png,jpg}" > output.txt

# Recursive batch processing
rika "**/*.pdf" > all_pdfs.txt
```

## Advanced Usage

### Integration with Other Tools

```bash
# Process metadata with jq
rika -s- -t- -f j document.pdf | jq '.metadata'

# Filter specific metadata fields
rika -s- -t- -f j "*.pdf" | jq '.metadata.author'

# Count pages across multiple documents
rika -s- -t- -f j "**/*.pdf" | jq '.metadata.pages' | awk '{sum+=$1} END {print sum}'

# Search text content across documents
rika -s- -m- "**/*.pdf" | grep -i "important term"
```

### Environment Variables

```bash
# Set default options
export RIKA_OPTIONS="-f j -t-"  # JSON format, metadata only

# Use the options (will use defaults from environment)
rika document.pdf

# Override specific options
rika -t document.pdf  # Override to include text
```

## Best Practices

1. **Always quote wildcard patterns** to prevent unexpected shell expansion
2. **Use the dry-run option** (`-n`) to preview command execution before processing files
3. **Set environment variables** for frequently used options to save typing
4. **Choose appropriate output formats** for your needs:
      - JSON (`-f j`) for machine processing and scripting
      - YAML (`-f y`) for human-readable structured output
      - AwesomePrint (`-f a`) for detailed visual inspection
      - Pretty JSON (`-f J`) for formatted JSON output
5. **Combine with other command-line tools** for powerful workflows
6. **Use content flags** (`-m-` and `-t-`) to include only what you need
7. **Save output to files** for later reference or processing
8. **Process files in batches** when working with multiple documents