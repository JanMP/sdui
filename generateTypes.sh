#!/bin/bash

# Get the output file name and folder
output_file="typeDeclarations.ts"
folder="coffee-compiled"

# Clean up previous compilation
rm -rf $folder
mkdir $folder
rm -f $output_file

# compile coffeescript to generate .js files
coffee --compile --output $folder .


# Use tsc to generate .d.ts files from the compiled JavaScript
echo '{
  "compilerOptions": {
    "declaration": true,
    "allowJs": true,
    "emitDeclarationOnly": true,
    "outDir": "coffee-compiled",
    "skipLibCheck": true
  },
  "include": ["./coffee-compiled/**/*.js"],
  "exclude": []
}' > tsconfig.temp.json

npx tsc -p tsconfig.temp.json --listFiles


# Find all .d.ts files in the folder and its subfolders
find "$folder" -type f -name '*.d.ts' | while read -r input_file; do
  echo "// Content from: $input_file" >> "$output_file"
  # Get relative path using perl instead of realpath
  relative_path=$(perl -e 'use File::Spec; print File::Spec->abs2rel($ARGV[0])' "$input_file")
  input_file_without_extension="${relative_path%.d.ts}"
  echo "export * from './$input_file_without_extension'" >> "$output_file"
  echo "" >> "$output_file"  # Add a newline for separation
done

# Clean up temporary files
rm tsconfig.temp.json

echo "Combined .d.ts files into $output_file"