{ pkgs }:

pkgs.writeShellScriptBin "nChain" ''
  source $HOME/.config/nChain/scripts/settings.sh
  config_dir="$HOME/.config/nChain"
  themes_dir="$HOME/.config/nChain/themes"

  use_launcher=true  
  unlink_all=false
  add_link=false
  show_links=false
  unlink_theme=""

  themes_to_unlink=($(ls "$config_dir"/links))

  optional_command=""

  # Function to display help
  display_help() {
    echo "Options:"
    echo "  -c                Display categories and subcategories."
    echo "  -h                Display this help message."
    echo "  -d                Unlink all themes and exit. *WARNING* ONLY USE THIS IF YOU KNOW WHAT YOU ARE DOING."
    echo "  -l [THEME] [OPT]  Add links to a theme. This will not overwrite any links you currently might have."
    echo "  -s                Show current linked themes."
    echo "  -t [THEME]        Change to specified theme."
    echo "  -u [THEME]        Unlink the specified theme."
    echo ""
    echo "                    Not choosing an option will run nChain with the launcher set in settings.sh"
    exit 0
  }

  display_categories() {
    for category in "''${!categories[@]}"; do
      echo "$category"
    done
  }

  display_subcategories() {
    local selected_category="$1"
    for subcategory in ''${categories[$selected_category]}; do
      echo "$subcategory"
    done
  }

  # options
  while getopts "cdhl:st:u:" opt; do
    case $opt in
      c)
        use_launcher=false
        display_categories_flag=true
        ;;
      d)
        unlink_all=true
        break
        ;;
      h)
        display_help
        ;;
      l)
        add_link=true
        link_dir="$OPTARG"
        # Check if there is an additional argument after -l
        if [ $# -gt 2 ] && [[ ! "$3" =~ ^- ]]; then
          optional_command="$3"
          shift 2  # Move to the next option
        fi
        ;;
      s)
        show_links=true
        ;;
      t)
        use_launcher=false
        theme_to_link="$OPTARG"
        ;;
      u)
        unlink_theme="$OPTARG"
        ;;
      \?)
        echo "Invalid option: -$OPTARG" >&2
        exit 1
        ;;
    esac
  done

  if [ "$unlink_all" = true ]; then
    if [ -n "$themes_to_unlink" ]; then
      # Display a warning and get user confirmation
      echo -e "\e[91m*WARNING* This will delete all your symlinks created by nChain. Are you sure you want to do this? (confirm with yes/no)\e[0m"
      read -r confirmation

      if [ "$confirmation" = "yes" ]; then

        for theme in "''${themes_to_unlink[@]}"; do
          $config_dir/scripts/linkGen.sh -d $theme
        done

      else
        echo "Operation canceled."
        exit 0
      fi
    else
      echo "No previous theme to unlink."
    fi
    exit 0
  fi

  shift $((OPTIND-1))

  if [ -n "$unlink_theme" ]; then
    if [ -n "$themes_to_unlink" ]; then
      # Check if the specified theme exists in themes_to_unlink
      if [[ " ''${themes_to_unlink[@]} " =~ " $unlink_theme " ]]; then
        $config_dir/scripts/linkGen.sh -d "$unlink_theme"
        exit 0
      else
        echo "Theme '$unlink_theme' not found in the list of themes to unlink."
        exit 1
      fi
    else
      echo "No previous themes to unlink."
      exit 1
    fi
  fi

  if [ "$show_links" = true ]; then
    echo "Current linked themes:"
    for file in "$config_dir/links"/*; do
      echo "$(basename "$file")"
    done
    exit 0
  fi

  # Check if the -link option was provided
  if [ "$add_link" = true ]; then
    if [ -z "$link_dir" ]; then
      echo "Error: -l (link) option requires an argument for the link directory."
      exit 1
    fi
    # Add the optional command to the linkGen.sh invocation
    if [ -n "$optional_command" ]; then
      "$config_dir/scripts/linkGen.sh" -l "$link_dir" "$optional_command"
    else
      "$config_dir/scripts/linkGen.sh" -l "$link_dir"
    fi
    exit 0
  fi

  if [ "$display_categories_flag" = true ]; then
    selected_category=$(printf "%s\n" "$(display_categories)" | eval "$launcher")
    if [ -n "$selected_category" ]; then
      selected_subcategory=$(printf "%s\n" "$(display_subcategories "$selected_category")" | eval "$launcher")
      if [ -n "$selected_subcategory" ]; then
        theme_to_link="$selected_subcategory"
      fi
    fi
    echo "$theme_to_link"
  fi

  if [ "$use_launcher" = true ]; then
    if [ "$launcher" = "" ]; then
      echo "No launcher is set in settings.sh. For assistance, run 'nChain -h' or refer to the README file on the GitHub page."
      exit 1
    fi

    available_themes=()
    while IFS= read -r line; do
      theme_name=$(basename "$line")

      # Check if the theme_name matches any of the patterns in folders_to_skip
      skip_theme=false
      for pattern in "''${folders_to_skip[@]}"; do
        if [[ $pattern == *\** ]]; then
          # Pattern contains a wildcard, so use wildcard matching
          if [[ $theme_name == *$pattern* ]]; then
            skip_theme=true
            break
          fi
        else
          # Pattern does not contain a wildcard, so use exact matching
          if [ "$theme_name" == "$pattern" ]; then
            skip_theme=true
            break
          fi
        fi
      done

      if [ "$skip_theme" = false ]; then
        available_themes+=("$theme_name")
      fi
    done < <(find "$themes_dir"/* -maxdepth 0 -type d -printf "%f\n")

    theme_to_link=$(printf "%s\n" "''${available_themes[@]}" | eval "$launcher")
  fi


  if [ -n "$theme_to_link" ]; then

    for command in "''${pre_commands[@]}"; do
      eval "$command"
    done

    if [ -n "$themes_to_unlink" ]; then
      for theme in "''${themes_to_unlink[@]}"; do
        $config_dir/scripts/linkGen.sh -d $theme
      done
    fi

    $config_dir/scripts/linkGen.sh -l "$theme_to_link" 

    # Run optional commands after the theme is set. 
    # These commands are only for the specific theme. Create yourThemeName.sh under scripts for this function
    if [ -f "$config_dir/scripts/$theme_to_link.sh" ]; then
      "$config_dir/scripts/$theme_to_link.sh"
    else
      # Run optional commands after the theme is set. 
      for command in "''${post_commands[@]}"; do
        eval "$command"
      done
    fi
  fi
''
