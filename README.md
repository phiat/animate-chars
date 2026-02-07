# animate-chars

![Demo](cham-dog.gif)

A CLI tool for animating Unicode characters and browsing the entire Unicode space.

## Features

- **Animate** any sequence of characters as a terminal spinner
- **Interactive browser** to explore and select Unicode characters
- **Navigate** with configurable step sizes (10, 50, 100, 500, 1000)
- **Quick jump** to popular ranges (Emoji, Box Drawing, Braille, Hiragana, Cham)
- **Save** character collections for reuse
- **Inspect** codepoints with hex and decimal values

## Quick Start

```bash
# Default animation
./animate.sh

# Interactive Unicode browser
./animate.sh -i

# Animate from saved file
./animate.sh -f selected_chars.txt

# Show codepoints
./animate.sh --show --range 0x1F600:10
```

## Interactive Mode

```bash
./animate.sh -i [START_ADDRESS]
```

**Controls:**
- `0-9` — Select character (allows duplicates)
- `n/p` — Next/previous page
- `j/k` — Jump ±100 codepoints
- `J/K` — Jump ±1000 codepoints
- `+/-` — Adjust step size
- `g` — Goto specific address
- `s` — Save selection
- `q` — Quit

## Options

```
--range START:LENGTH    Unicode range (e.g., 0xAB20:7)
--chars "a,b,c"         Comma-separated character list
--file FILE             Load characters from saved file
--speed SECONDS         Animation speed (default: 0.1)
--timer SECONDS         Run for specified duration
--once                  Single pass through characters
--show                  Print characters with codepoints
--interactive [START]   Interactive Unicode browser
```

## Examples

```bash
# Fast animation
./animate.sh --speed 0.05

# Custom spinner
./animate.sh --chars "⠋,⠙,⠹,⠸,⠼,⠴,⠦,⠧,⠇,⠏"

# Browse emoji
./animate.sh -i 0x1F600

# Timed animation
./animate.sh --timer 10 --speed 0.1
```

## License

MIT
