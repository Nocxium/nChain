#!/usr/bin/env bash

target_dir="$HOME"

add_links() {
    if [ -z "$input_variable" ]; then
        echo "Error: Missing theme name to link"
        exit 1
    fi

    link_finder="${2:-$input_variable}"

    source_dir="$HOME/.config/nChain/themes/$input_variable"
    target_link_dir="$HOME/.config/nChain/links/${link_finder}"  # Use a different variable

    find "$source_dir" -type f -o -type d | while read source_item; do
        relative_path="${source_item#$source_dir}"

        target_item="$target_dir$relative_path"

        if [ -d "$source_item" ]; then
            mkdir -p "$target_item"
        elif [ -f "$source_item" ]; then
            if [ ! -e "$target_item" ]; then
                ln -s "$source_item" "$target_item"

                echo "$target_item" >> "$target_link_dir"
                echo "Linked: $target_item" 
            else
                echo "Conflict: $target_item (skipping)"
            fi
        fi
    done
}

delete_links() {
    if [ -z "$input_variable" ]; then
        echo "Error: Missing theme name to unlink."
        exit 1
    fi

    link_finder="$HOME/.config/nChain/links/${input_variable}"

    if [ ! -f "$link_finder" ]; then
        echo "Error: $link_finder not found."
        exit 1
    fi

    declare -A folder_status

    while IFS= read -r link_path; do
        if [ -L "$link_path" ]; then
            rm "$link_path"
            echo "Removed: $link_path"

            link_folder=$(dirname "$link_path")

            folder_status["$link_folder"]="not_empty"
        else
            echo "Not found: $link_path"
        fi
    done < "$link_finder"

    rm "$link_finder"

    for folder in "${!folder_status[@]}"; do
        if [ "${folder_status[$folder]}" == "not_empty" ] && [ -z "$(ls -A "$folder")" ]; then
            rmdir "$folder"
            echo "Removed empty folder: $folder"
        fi
    done
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -l | -link)
            input_variable="$2"
            shift 2
            if [ -n "$1" ]; then
                link_finder="$1"
            else
                link_finder="$input_variable"
            fi
            add_links "$input_variable" "$link_finder"
            ;;
        -d | -delete)
            input_variable="$2"
            delete_links
            ;;
        *)
            exit 1
            ;;
    esac
    shift
done
