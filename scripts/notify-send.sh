#!/usr/bin/env bash

# Define the directory
directory="$HOME/.config/nChain/links"

if [ -d "$directory" ]; then
  for file in "$directory"/*; do
    if [ "$(basename "$file")" != "default" ] && [ -f "$file" ]; then
      filename=$(basename "$file")
      filename="${filename^}"
      notify-send -u low -a nChain "Theme: $filename"
    fi
  done
fi

