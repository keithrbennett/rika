# Rika Examples

This document provides practical examples of how to use Rika for both business and personal use cases.

## Basic Usage

### Extract Metadata and Text from a Single File
```bash
rika document.pdf  # Default: outputs both metadata and text
rika image.png     # Works with image files too
```

### Extract Metadata and Text from Multiple Files
```bash
rika "*.pdf"  # Quote wildcards to prevent potentially problematic shell expansion
rika "**/*.pdf"  # Recursive; search this directory and all its subdirectories
rika "reports/*.pdf" "drafts/*.doc"  # Different directories
rika "**/*.pdf" "**/*.doc"  # Recursive search for multiple types
rika "**/*.{pdf,doc}"  # Shorthand form for above
```

### Extract Metadata and Text from a URL
```bash
rika https://example.com/document.pdf
rika https://example.com/image.png  # Works with image URLs too
```

### Control Output Content
```bash
# Default: outputs filespec banner, metadata, and text
rika document.pdf

# Metadata only (exclude text), includes filespec banner
rika -t- document.pdf

# Text only (exclude metadata), includes filespec banner
rika -m- document.pdf

# Disable filespec banner, outputs metadata and text
rika -s- document.pdf

# Combine with format options
rika -t- -f a document.pdf  # Metadata only, in Awesome Print format, includes filespec banner
rika -m- -f a document.pdf  # Text only, in Awesome Print format, includes filespec banner
rika -s- -t- -f j document.pdf  # Metadata only, JSON format, no filespec banner, for machine readability
```

## Business Use Cases

### Batch Process Documents
```bash
# Process all PDFs in a directory
rika "*.pdf" > output.txt

# Process specific file types
rika "*.{pdf,doc,docx}" > output.txt

# Process both documents and images
rika "*.{pdf,png,jpg}" > output.txt
```

### Extract Metadata for Document Management
```bash
# Get metadata in JSON format, with filespec banner for human readability
rika -t- -f j document.pdf

# Get metadata in JSON format, no banner, good for piping data
rika -t- -f j -s- document.pdf

# Get both metadata and text, and ouput them in different formats
rika -f ja document.pdf  # JSON for metadata, Awesome Print for text
```

### Process Documents from a Web Server
```bash
# Process multiple documents from a web server
rika https://example.com/docs/*.pdf
rika https://example.com/images/*.png  # Process images from a web server
```

### Preview Command Execution
```bash
# See what files would be processed without actually processing them
rika -n "*.pdf"
rika -n "*.{pdf,png}"  # Preview processing of both documents and images
```

## Personal Use Cases

### Extract Metadata and Text from Personal Documents
```bash
# Extract from a scanned document
rika scanned_document.pdf

# Extract from multiple personal documents
rika "personal/*.pdf"

# Extract from personal photos
rika "photos/*.png"  # Process personal photos
```

### Convert Documents to Text
```bash
# Convert a document to plain text
rika -m- document.pdf > document.txt

# Convert multiple documents to text
rika -m- "*.pdf" > all_documents.txt

# Extract text from images (OCR)
rika -m- "*.png" > image_text.txt
```

### Extract Metadata from Personal Files
```bash
# Get metadata in a readable format
rika -t- -f a document.pdf  # AwesomePrint format

# Get metadata in JSON format for further processing
rika -t- -f j document.pdf > metadata.json

# Get image metadata
rika -t- -f j image.png > image_metadata.json
```

## Advanced Usage

### Use Environment Variables for Options
```bash
# Set default options
export RIKA_OPTIONS="-f j -t-"  # JSON format, metadata only

# Use the options
rika document.pdf
```

### Process Files with Special Characters
```bash
# Use single quotes to prevent shell interpretation
rika 'file with spaces.pdf'

# Use double quotes to allow variable expansion
rika "$HOME/documents/*.pdf"
```

### Combine with Other Tools
```bash
# Extract text and search for specific content
rika -m- document.pdf | grep "search term"

# Extract metadata and process with jq
rika -s- -t- -f j document.pdf | jq '.metadata'
rika -s- -t- -f j image.png | jq '.metadata'

# Process multiple files with jq
rika -s- -t- -f j "*.pdf" | jq '.metadata'
```

## Tips and Best Practices

1. Always quote wildcard patterns to prevent shell expansion
2. Use the dry-run option (-n) to preview command execution
3. Use environment variables for frequently used options
4. Combine with other command-line tools for powerful workflows
5. Use appropriate output formats for your needs:
   - JSON (-f j) for machine processing
   - YAML (-f y) for human readability
   - AwesomePrint (-f a) for detailed inspection
   - Pretty JSON (-f J) for formatted output
6. Use -m- and -t- flags to exclude metadata or text output respectively
7. Combine format options with content flags for customized output 