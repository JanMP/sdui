#!/bin/bash

# compile coffeescript to generate .js and .d.ts files.
coffee --compile --output coffee-compiled .


cp customTypes.ts typeDeclarations.ts

# Get the output file name and folder
output_file="typeDeclarations.ts"
folder="coffee-compiled"

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
  echo "\n" >> "$output_file"  # Add a newline for separation
done

echo "Combined .d.ts files into $output_file"