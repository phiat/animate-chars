#!/bin/bash

# Default animation characters
DEFAULT_CHARS=("ꬠ" "ꬡ" "ꬢ" "ꬣ" "ꬤ" "ꬥ" "ꬦ")

# Default settings
SPEED=0.1
ONCE=false
SHOW=false
TIMER=0
INTERACTIVE=false
INTERACTIVE_START=0xAB20
CHAR_FILE=""
chars=()

# Usage function
usage() {
  cat << EOF
Usage: $(basename "$0") [OPTIONS]

Animate a sequence of characters in the terminal.

OPTIONS:
  --range START:LENGTH    Unicode range (e.g., 0xAB20:7)
  --chars "a,b,c"         Comma-separated character list
  --file FILE             Load characters from saved file
  -f FILE                 Short form of --file
  --speed SECONDS         Animation speed in seconds (default: 0.1)
  --once                  Run once instead of looping infinitely
  --timer SECONDS         Run animation for specified duration
  --show                  Print characters with codepoints (no animation)
  --interactive [START]   Interactive Unicode browser (default: 0xAB20)
  -i [START]              Short form of --interactive
  -h, --help             Show this help message

EXAMPLES:
  $(basename "$0")                              # Use default characters
  $(basename "$0") --speed 0.05                 # Faster animation
  $(basename "$0") --chars "⠋,⠙,⠹,⠸,⠼,⠴,⠦,⠧,⠇,⠏"  # Custom spinner
  $(basename "$0") --file selected_chars.txt    # Load from saved file
  $(basename "$0") --range 0xAB20:7 --once      # Unicode range, single pass
  $(basename "$0") --timer 10 --speed 0.05      # Animate for 10 seconds
  $(basename "$0") --show --range 0xAB20:16     # Show Unicode codepoints
  $(basename "$0") -i                           # Interactive Unicode browser
  $(basename "$0") -i 0x2800                    # Browse Braille patterns

EOF
  exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --range)
      IFS=':' read -r start length <<< "$2"
      # Convert hex to decimal if needed
      if [[ $start == 0x* ]]; then
        start=$((start))
      fi
      # Generate character array from Unicode range
      for ((i=0; i<length; i++)); do
        hex=$(printf '%08x' $((start + i)))
        # shellcheck disable=SC2059
        chars+=("$(printf "\U$hex")")
      done
      shift 2
      ;;
    --chars)
      IFS=',' read -ra chars <<< "$2"
      shift 2
      ;;
    --file|-f)
      CHAR_FILE="$2"
      shift 2
      ;;
    --speed)
      SPEED=$2
      shift 2
      ;;
    --once)
      ONCE=true
      shift
      ;;
    --timer)
      TIMER=$2
      shift 2
      ;;
    --show)
      SHOW=true
      shift
      ;;
    --interactive|-i)
      INTERACTIVE=true
      if [[ -n "$2" && "$2" != -* ]]; then
        INTERACTIVE_START="$2"
        # Convert hex to decimal if needed
        if [[ $INTERACTIVE_START == 0x* ]]; then
          INTERACTIVE_START=$((INTERACTIVE_START))
        fi
        shift 2
      else
        shift
      fi
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Unknown option: $1"
      usage
      ;;
  esac
done

# Load characters from file if specified
if [ -n "$CHAR_FILE" ]; then
  if [ ! -f "$CHAR_FILE" ]; then
    echo "Error: File not found: $CHAR_FILE"
    exit 1
  fi
  # Read the last non-empty, non-comment line
  char_line=$(grep -v '^#' "$CHAR_FILE" | grep -v '^[[:space:]]*$' | tail -1)
  if [ -z "$char_line" ]; then
    echo "Error: No character data found in file: $CHAR_FILE"
    exit 1
  fi
  # Parse comma-separated characters
  IFS=',' read -ra chars <<< "$char_line"
fi

# Use defaults if no characters specified
if [ ${#chars[@]} -eq 0 ]; then
  chars=("${DEFAULT_CHARS[@]}")
fi

# Validate speed
if ! [[ $SPEED =~ ^[0-9]+\.?[0-9]*$ ]]; then
  echo "Error: --speed must be a number"
  exit 1
fi

# Validate timer
if ! [[ $TIMER =~ ^[0-9]+\.?[0-9]*$ ]]; then
  echo "Error: --timer must be a number"
  exit 1
fi

# Check if character is printable (skip control chars and common unprintables)
is_printable() {
  local codepoint=$1
  # Skip control characters and common unprintable ranges
  if (( codepoint < 32 )) || \
     (( codepoint >= 127 && codepoint <= 159 )) || \
     (( codepoint >= 0xFFFE && codepoint <= 0xFFFF )) || \
     (( codepoint >= 0xD800 && codepoint <= 0xDFFF )); then
    return 1
  fi
  return 0
}

# Interactive mode - browse and select Unicode characters
interactive_mode() {
  local position=$INTERACTIVE_START
  local max_position=0x10FFFF  # Max Unicode codepoint
  local display_size=10
  local step_size=10
  local selected=()
  local key

  # Trap Ctrl+C to exit cleanly
  trap 'printf "\033[?25h\n"; exit 0' INT

  # Hide cursor
  printf "\033[?25l"

  while true; do
    # Clear screen
    clear

    # Build page of characters (shows all, including unprintables)
    local page_chars=()
    local page_codes=()
    local current=$position

    for ((i=0; i<display_size && current<max_position; i++)); do
      local hex
      hex=$(printf '%08x' "$current")
      local char
      # shellcheck disable=SC2059
      char=$(printf "\U$hex" 2>/dev/null)
      # Show character even if empty/unprintable (may render as □ or blank)
      page_chars+=("${char:- }")
      page_codes+=("$current")
      ((current++))
    done

    # Display header (fixed width, 60 chars)
    printf "┌─ Unicode Browser ────────────────────────────────────────┐\n"
    printf "│ Range: 0x%05X-0x%05X%36s│\n" "$position" "$((position + display_size - 1))" ""
    if [ ${#selected[@]} -gt 0 ]; then
      local selected_preview="${selected[*]}"
      # Truncate if too long
      if [ ${#selected_preview} -gt 30 ]; then
        selected_preview="${selected_preview:0:27}..."
      fi
      printf "│ Step: %-4d%31sSelected: %-6s│\n" "$step_size" "" "${#selected[@]}"
    else
      printf "│ Step: %-4d%31sSelected: (none) │\n" "$step_size" ""
    fi
    printf "└──────────────────────────────────────────────────────────┘\n"

    # Display characters
    for i in "${!page_chars[@]}"; do
      local codepoint=${page_codes[$i]}
      local char="${page_chars[$i]}"
      local hex
      hex=$(printf "%X" "$codepoint")
      printf "[%d] U+%-6s (%6d) %s\n" "$i" "$hex" "$codepoint" "$char"
    done

    # Display help (compact)
    printf "\n"
    printf "0-9:select | n:next p:prev | j:+100 k:-100 | J:+1000 K:-1000\n"
    printf "+/-:step size | g:goto | s:save q:quit\n"

    # Read single keypress
    read -rsn1 key

    case "$key" in
      [0-9])
        # Select character (allows duplicates for animation sequences)
        if [ "$key" -lt "${#page_chars[@]}" ]; then
          local selected_char="${page_chars[$key]}"
          selected+=("$selected_char")
        fi
        ;;
      n)
        # Next page
        position=$((position + step_size))
        ;;
      p)
        # Previous page
        position=$((position - step_size))
        if [ "$position" -lt "$INTERACTIVE_START" ]; then
          position=$INTERACTIVE_START
        fi
        ;;
      j)
        # Jump forward 100
        position=$((position + 100))
        ;;
      k)
        # Jump back 100
        position=$((position - 100))
        if [ "$position" -lt "$INTERACTIVE_START" ]; then
          position=$INTERACTIVE_START
        fi
        ;;
      J)
        # Jump forward 1000
        position=$((position + 1000))
        ;;
      K)
        # Jump back 1000
        position=$((position - 1000))
        if [ "$position" -lt "$INTERACTIVE_START" ]; then
          position=$INTERACTIVE_START
        fi
        ;;
      +)
        # Increase step size
        if [ $step_size -eq 10 ]; then
          step_size=50
        elif [ $step_size -eq 50 ]; then
          step_size=100
        elif [ $step_size -eq 100 ]; then
          step_size=500
        elif [ $step_size -eq 500 ]; then
          step_size=1000
        fi
        ;;
      -)
        # Decrease step size
        if [ $step_size -eq 1000 ]; then
          step_size=500
        elif [ $step_size -eq 500 ]; then
          step_size=100
        elif [ $step_size -eq 100 ]; then
          step_size=50
        elif [ $step_size -eq 50 ]; then
          step_size=10
        fi
        ;;
      g)
        # Goto address
        printf "\033[?25h\n"
        printf "Popular ranges:\n"
        # shellcheck disable=SC2059
        printf "  0x2500   $(printf '\U00002500')  Box Drawing (borders, lines)\n"
        # shellcheck disable=SC2059
        printf "  0x2800   $(printf '\U00002800')  Braille Patterns\n"
        # shellcheck disable=SC2059
        printf "  0x3040   $(printf '\U00003040')  Hiragana (Japanese)\n"
        # shellcheck disable=SC2059
        printf "  0xAA00   $(printf '\U0000AA00')  Cham\n"
        # shellcheck disable=SC2059
        printf "  0x1F600  $(printf '\U0001F600')  Emoji (faces, hands)\n"
        printf "\n"
        local goto_addr
        read -rp "Goto address: " goto_addr
        if [ -n "$goto_addr" ]; then
          # Convert hex to decimal if needed
          if [[ $goto_addr == 0x* ]]; then
            position=$((goto_addr))
          elif [[ $goto_addr =~ ^[0-9]+$ ]]; then
            position=$goto_addr
          else
            # Try parsing as hex without 0x prefix
            position=$((0x$goto_addr))
          fi
          # Ensure within valid range
          if [ "$position" -lt 0 ]; then
            position=0
          elif [ "$position" -gt "$max_position" ]; then
            position=$max_position
          fi
        fi
        printf "\033[?25l"
        ;;
      s)
        # Save and exit
        printf "\033[?25h\n"
        if [ ${#selected[@]} -eq 0 ]; then
          echo "No characters selected."
          exit 0
        fi

        # Prompt for filename
        local output_file
        read -rp "Save as (default: selected_chars.txt): " output_file
        if [ -z "$output_file" ]; then
          output_file="selected_chars.txt"
        fi

        # Add .txt extension if not present
        if [[ ! "$output_file" =~ \. ]]; then
          output_file="${output_file}.txt"
        fi

        # Create comma-separated list
        {
          echo "# Selected Unicode characters - generated by animate.sh"
          echo "# Usage: ./animate.sh --chars \"$(IFS=,; echo "${selected[*]}")\""
          echo ""
          IFS=,; echo "${selected[*]}"
        } > "$output_file"

        echo "Saved ${#selected[@]} characters to: $output_file"
        echo ""
        cat "$output_file"
        exit 0
        ;;
      q)
        # Quit without saving
        printf "\033[?25h\n"
        echo "Quit without saving."
        exit 0
        ;;
    esac
  done
}

# Show mode - print characters with codepoints and exit
if [ "$SHOW" = true ]; then
  for char in "${chars[@]}"; do
    # Get codepoint in decimal
    codepoint=$(printf "%d" "'$char")
    # Convert to hex
    hex=$(printf "%X" "$codepoint")
    # Print in format: U+XXXX (decimal) char
    printf "U+%s (%d) %s\n" "$hex" "$codepoint" "$char"
  done
  exit 0
fi

# Animation loop
animate() {
  for char in "${chars[@]}"; do
    printf "\r%s " "$char"
    sleep "$SPEED"
  done
}

# Run interactive mode if requested
if [ "$INTERACTIVE" = true ]; then
  interactive_mode
fi

# Trap Ctrl+C to clean up
trap 'printf "\n"; exit 0' INT

# Run animation
if [ "$ONCE" = true ]; then
  animate
  printf "\n"
elif [ "$TIMER" -gt 0 ]; then
  # Timer mode - run for specified duration
  start_time=$(date +%s)
  end_time=$((start_time + TIMER))
  while [ "$(date +%s)" -lt "$end_time" ]; do
    animate
  done
  printf "\n"
else
  # Infinite loop
  while true; do
    animate
  done
fi
