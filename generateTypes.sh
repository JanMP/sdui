#!/bin/bash

# compile coffeescript to generate .js and .d.ts files.
coffee --compile --output coffee-compiled .


# Check if at least two arguments are provided (output file and folder)
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 output.d.ts folder"
  exit 1
fi

# Get the output file name and folder
output_file=$1
folder=$2

# Check if the folder exists
if [ ! -d "$folder" ]; then
  echo "Error: Folder '$folder' does not exist."
  exit 1
fi

# Initialize the output file
echo "// Combined .d.ts file" >> "$output_file"

# Find all .d.ts files in the folder and its subfolders
find "$folder" -type f -name '*.d.ts' | while read -r input_file; do
  echo "// Content from: $input_file" >> "$output_file";
  input_file_without_extension="${input_file%.d.ts}"
  echo "export * from './$input_file_without_extension'" >> "$output_file"
  # Replace 'export function' with 'export declare function' and append to the output file
  # sed 's/export function/export declare function/g' "$input_file" >> "$output_file"
  
  echo "\n" >> "$output_file"  # Add a newline for separation

done

echo "Combined .d.ts files into $output_file"