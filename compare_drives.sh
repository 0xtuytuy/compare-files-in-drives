#!/bin/bash

# Function to prompt the user to select a directory using Finder
select_directory() {
    osascript <<EOT
    tell application "Finder"
        activate
        set theFolder to choose folder with prompt "Select a drive:"
        return POSIX path of theFolder
    end tell
EOT
}

# Prompt the user to select the first drive
echo "Please select the first drive."
DRIVE1_PATH=$(select_directory)
echo "Selected Drive 1: $DRIVE1_PATH"

# Prompt the user to select the second drive
echo "Please select the second drive."
DRIVE2_PATH=$(select_directory)
echo "Selected Drive 2: $DRIVE2_PATH"

# Output file for differences
OUTPUT_FILE="difference_report.txt"

# Function to compare two directories
compare_directories() {
    local dir1="$1"
    local dir2="$2"

    echo "Comparing files in $dir1 and $dir2..." >> "$OUTPUT_FILE"
    echo "=============================================" >> "$OUTPUT_FILE"

    # Find files in the first directory and compare them with the second
    while IFS= read -r file1; do
        # Remove the base directory to get the relative file path
        relative_path="${file1#$dir1/}"
        file2="$dir2/$relative_path"

        if [[ -f "$file1" ]]; then
            if [[ ! -f "$file2" ]]; then
                echo "Missing in $dir2: $relative_path" >> "$OUTPUT_FILE"
            else
                size1=$(stat -c%s "$file1")
                size2=$(stat -c%s "$file2")

                if [[ "$size1" -ne "$size2" ]]; then
                    echo "Size mismatch for $relative_path: $size1 vs $size2" >> "$OUTPUT_FILE"
                fi
            fi
        fi
    done < <(find "$dir1" -type f \( \
        -not -path "*/\$RECYCLE*" \
        -not -path "*/.DS_Store" \
        -not -path "*/Thumbs.db" \
        -not -path "*/System Volume Information*" \
        \))

    # Find files in the second directory that are not in the first
    while IFS= read -r file2; do
        relative_path="${file2#$dir2/}"
        file1="$dir1/$relative_path"

        if [[ -f "$file2" && ! -f "$file1" ]]; then
            echo "Extra in $dir2: $relative_path" >> "$OUTPUT_FILE"
        fi
    done < <(find "$dir2" -type f \( \
        -not -path "*/\$RECYCLE*" \
        -not -path "*/.DS_Store" \
        -not -path "*/Thumbs.db" \
        -not -path "*/System Volume Information*" \
        \))

    echo "=============================================" >> "$OUTPUT_FILE"
    echo "Comparison completed." >> "$OUTPUT_FILE"
}

# Main script
if [[ -z "$DRIVE1_PATH" || -z "$DRIVE2_PATH" ]]; then
    echo "One or both directories were not selected."
    exit 1
fi

# Clear previous output file
> "$OUTPUT_FILE"

# Compare the directories
compare_directories "$DRIVE1_PATH" "$DRIVE2_PATH"

echo "Differences written to $OUTPUT_FILE"