#!/usr/bin/env bash
# launcher="rofi -dmenu -i -p 'Select theme:'"

folders_to_skip=(
  # "folder_one"
  # "folder_two"
)

pre_commands=(
  # These commands are running before the theme change'"
)

post_commands=(
  # Optional commands to run after the theme change. Put each command inside "". Here are some examples:
  # "killall .dunst-wrapped"
  # "kill -SIGUSR1 $(pidof kitty)"
  # "$HOME/.config/nChain/scripts/notify-send.sh &"
)

# Define optional categories and subcategories
declare -A categories
categories=(
  # ["Flower"]="Autumn Chiaroscuro Winter-green"
  # ["Experiment"]="Fern Leaf-seasons MoonScape Snowy-Umbrella Trippy-Mountain Yellow-haze"
)
