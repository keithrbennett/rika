# Rika Examples

This document provides practical examples of how to use Rika for extracting metadata and text from various file types.

## Table of Contents
- [Getting Started](#getting-started)
- [File Selection](#file-selection)
- [Output Options](#output-options)
- [Working with URLs](#working-with-urls)
- [Advanced Usage](#advanced-usage)
      - [Integration with Other Tools](#integration-with-other-tools)
      - [Environment Variables](#environment-variables)
- [Best Practices](#best-practices)
- [Usage in Your Ruby Code](#usage-in-your-ruby-code)

## Getting Started

### Basic Command Structure
```bash
rika [options] <filespec>...  # Process files with optional flags
```

### Simple Examples
```bash
# Process a single file (outputs metadata, text, and filespec banner by default)
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
rika "*.pdf" "*.doc" "*.docx"
rika "*.{pdf,doc,docx}"

# Process files from different directories
rika "reports/*.pdf" "drafts/*.doc"
rika "{reports,drafts}/*.pdf" "drafts/*.doc"

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

# Using variables the string must be double quoted; single quotes will suppress variable expansion
rika "$HOME/documents/*.pdf"
```

## Output Options

### Control Output Content
```bash
# Default: outputs filespec banner, metadata, and text
rika document.pdf

# Metadata and banner only (exclude text)
rika -t- document.pdf

# Text and banner only (exclude metadata)
rika -m- document.pdf

# Disable filespec banner (for cleaner and/or machine readable output)
rika -s- document.pdf
```

### Output Formats
```bash
# JSON format (-f j)
rika -f j document.pdf

# Pretty JSON format (-f J)
rika -f J document.pdf

# YAML format (-f y)
rika -f y document.pdf

# AwesomePrint format (-f a)
rika -f a document.pdf

# Metadata in JSON format, text in AwesomePrint format
rika -f ja document.pdf
```

### Combining Output Options
```bash
# Metadata only in JSON format with banner
rika -t- -f j document.pdf

# Text only in default format without banner
rika -s- -m- document.pdf

# Metadata only without banner, in machine-readable JSON format (ideal for scripting)
rika -t- -s- -f j document.pdf
```

## Working with URLs

```bash
# Process a document from a web server
rika https://example.com/docs/document.pdf

# Process an image from a web server
rika https://example.com/images/image.png
```

## Advanced Usage

### Integration with Other Tools

```bash
# Filter specific metadata fields with jq
rika -s- -t- -f j document.pdf | jq '."a-metadata-key"'

# Search text content across documents
rika -s- -m- "**/*.pdf" | grep -i "important term"

# View output in pager. Also, this can be better than grep for searching a term
rika *pdf | $PAGER
rika *pdf | less

# For long jobs, send to stdout to monitor progress and output, but also save to a file
rika **/*.pdf | tee 'yyyy-mm-dd-pdf-parsed-output.txt'

# Include any stderr output using 2>&1
rika **/*.pdf 2>&1 | tee 'yyyy-mm-dd-pdf-parsed-output.txt'

# Use a diff tool to compare periodic outputs of rika parses for changing data sets
diff yesterday-parsed-text.txt today-parsed-text.txt

# Use git to track parsed text - send rika output to the same file periodically and commit it to git
rika **/* > parsed-output.txt && git add parsed-output.txt && git commit -m "Parse of $(date)" && git push origin main 

# Time a run
time rika **/*pdf
```

### Environment Variables

```bash
# Set default options
export RIKA_OPTIONS="-f j -t- -s-"  # JSON format, metadata only

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
      - JSON or YAML (`-f j`, `-f J`, or `-f y`) for machine processing and scripting
      - Pretty JSON or YAML (`-f J` or `-f y`) for human-readable structured output
      - AwesomePrint, YAML, or Pretty JSON (`-f a`, `-f y`, `-f J`) for human visual inspection
5. **Combine with other command-line tools** for powerful workflows
6. **Use content flags** (`-m-`, `-t-`, and `-s-`) to include only what you need
7. **Save output to files** for later reference or processing
8. **Process files in batches** when working with multiple documents
9. **Be careful with overlapping filespecs** - a file matching multiple patterns will be processed multiple times:
   ```bash
   # Bad: processes PDFs in docs/ twice
   rika "**/*.pdf" "docs/*.pdf"
   
   # Good: use single filespec
   rika "**/*.pdf"
   
   # Good: use non-overlapping patterns
   rika "docs/*.pdf" "archive/*.pdf"
   ```

## Usage in Your Ruby Code

```ruby
require 'rika'

# Process a single file
doc = Rika.parse_file('document.pdf')
puts doc.metadata
puts doc.text

# Process multiple files
Dir.glob('**/*.pdf').each do |file|
  doc = Rika.parse_file(file)
  puts doc.metadata
end

# Process a URL
doc = Rika.parse_url('https://example.com/document.pdf')
puts doc.metadata
```