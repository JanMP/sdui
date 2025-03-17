#!/bin/bash

# Get the output file name and folder
output_file="typeDeclarations.d.ts"
folder="coffee-compiled"

# Clean up previous compilation
rm -rf $folder
mkdir -p $folder
rm -f $output_file

# Compile coffeescript to generate .js files
coffee --compile --output $folder .

# Use tsc to generate .d.ts files from the compiled JavaScript
echo '{
  "compilerOptions": {
    "declaration": true,
    "allowJs": true,
    "emitDeclarationOnly": true,
    "outDir": "coffee-compiled",
    "skipLibCheck": true,
    "target": "es2020",
    "module": "commonjs",
    "strict": false,
    "noImplicitAny": false,
    "esModuleInterop": true
  },
  "include": ["./coffee-compiled/**/*.js"],
  "exclude": []
}' > tsconfig.temp.json

npx tsc -p tsconfig.temp.json

# Create the output file with a header
echo "/**" > "$output_file"
echo " * Combined TypeScript declarations" >> "$output_file"
echo " * Generated on $(date)" >> "$output_file"
echo " */" >> "$output_file"
echo "" >> "$output_file"

# Declare a global namespace to contain all declarations
echo "declare namespace SduiComponents {" >> "$output_file"
echo "" >> "$output_file"

# Find all .d.ts files in the folder and its subfolders
find "$folder" -type f -name '*.d.ts' | sort | while read -r input_file; do
  echo "  // ====== From: $input_file ======" >> "$output_file"
  
  # Extract filename without path and extension for better error tracking
  file_name=$(basename "$input_file" .d.ts)
  
  # Process each file, maintaining function structure
  # Use more advanced sed to handle multi-line declarations
  # This approaches preserves entire declaration blocks
  (
    echo "  // File: $file_name"
    sed -E '
      # Skip import statements
      /^import/d;
      
      # Handle export statements - remove export keyword but keep declaration
      s/^export (default )?//;
      
      # Remove declare module without losing content
      s/^declare module "[^"]*" \{//;
      s/^\}$//;
      
      # Add indentation to all non-empty lines
      s/^(.+)/  \1/;
    ' "$input_file"
    echo ""
  ) >> "$output_file"
done

# Close the namespace
echo "}" >> "$output_file"

# Clean up temporary files
rm -f tsconfig.temp.json
rm -rf $folder

echo "Combined .d.ts file content into $output_file"