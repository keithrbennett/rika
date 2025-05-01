   # Rika Examples

   This document provides practical examples of how to use Rika.

   ## Basic Usage

   ### Extract Metadata and Text from a Single File
   ```bash
   rika document.pdf  # Default: outputs both metadata and text, with a human readable filespec banner
   rika image.png     # Works with image files too
   ```

   ### Extract Metadata and Text from Multiple Files
   ```bash
   rika "*.pdf"  # Quote wildcards to prevent potentially problematic shell expansion
   rika "**/*.pdf"  # Recursive; searches this directory and all its subdirectories
   rika "reports/*.pdf" "drafts/*.doc"  # Multiple filespecs/filemasks and directories are supported
   rika "**/*.pdf" "**/*.doc"  # Recursive search for multiple types
   rika "**/*.{pdf,doc}"  # Shorthand form for above
   ```

   ### Extract Metadata and Text from a URL
   ```bash
   rika https://example.com/docs/document.pdf  # Process a document from a web server
   rika https://example.com/images/image.png   # Process an image from a web server
   ```

   ### Preview Operations (Dry Run)
   ```bash
   # Preview what files would be processed without actually processing them
   rika -n "*.pdf"  # Preview PDF processing
   rika -n "*.{pdf,png}"  # Preview multiple file type processing
   rika -n "**/*.pdf"  # Preview recursive search
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

   ## Common Use Cases

   ### Batch Processing
   ```bash
   # Process all PDFs in a directory
   rika "*.pdf" > output.txt

   # Process specific file types
   rika "*.{pdf,doc,docx}" > output.txt

   # Process both documents and images
   rika "*.{pdf,png,jpg}" > output.txt
   ```

   ### Document Management
   ```bash
   # Extract metadata in different formats
   rika -t- -f j document.pdf  # JSON format with filespec banner
   rika -t- -f j -s- document.pdf  # JSON format without banner
   rika -t- -f a document.pdf  # AwesomePrint format
   rika -t- -f j image.png > metadata.json  # Save metadata to file

   # Get both metadata and text in different formats
   rika -f ja document.pdf  # JSON for metadata, Awesome Print for text
   ```

   ### Text Extraction
   ```bash
   # Extract text from a single document
   rika -b- -m- document.pdf > document.txt

   # Convert multiple documents to text
   rika -m- "*.pdf" > all_documents.txt

   # Extract and search for specific content
   rika -m- document.pdf | grep "search term"
   ```

   ## Advanced Usage

   ### Environment Variables
   ```bash
   # Set default options
   export RIKA_OPTIONS="-f j -t-"  # JSON format, metadata only

   # Use the options
   rika document.pdf
   ```

   ### Special Cases
   ```bash
   # Files with spaces
   rika 'file with spaces.pdf'

   # Use variables
   rika "$HOME/documents/*.pdf"
   ```

   ### Integration with Other Tools
   ```bash
   # Process with jq
   rika -s- -t- -f j document.pdf | jq '.metadata'
   rika -s- -t- -f j image.png | jq '.metadata'
   rika -s- -t- -f j "*.pdf" | jq '.metadata'
   ```

   ## Best Practices

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