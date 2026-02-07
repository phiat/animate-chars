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

```
┌─ Unicode Browser ────────────────────────────────────────┐
│ Range: 0xAB20-0xAB29                                     │
│ Step: 10                              Selected: (none)   │
└──────────────────────────────────────────────────────────┘
[0] U+AB20   ( 43808) ꬠ
[1] U+AB21   ( 43809) ꬡ
[2] U+AB22   ( 43810) ꬢ
[3] U+AB23   ( 43811) ꬣ
[4] U+AB24   ( 43812) ꬤ
[5] U+AB25   ( 43813) ꬥ
[6] U+AB26   ( 43814) ꬦ
[7] U+AB27   ( 43815) ꬧
[8] U+AB28   ( 43816) ꬨ
[9] U+AB29   ( 43817) ꬩ

0-9:select | n:next p:prev | j:+100 k:-100 | J:+1000 K:-1000
+/-:step size | g:goto | s:save q:quit
```

**Controls:**
- `0-9` — Select character (allows duplicates for sequences)
- `n/p` — Next/previous by step size (default: 10)
- `j/k` — Jump ±100 codepoints
- `J/K` — Jump ±1000 codepoints
- `+/-` — Adjust step size (10 → 50 → 100 → 500 → 1000)
- `g` — Goto specific address (shows popular ranges)
- `s` — Save selection (prompts for filename)
- `q` — Quit without saving

Always displays 10 characters per screen. Navigation is consistent and predictable.

## Options

```
--range START:LENGTH    Unicode range (e.g., 0xAB20:7)
--chars "a,b,c"         Comma-separated character list
--file, -f FILE         Load characters from saved file
--speed SECONDS         Animation speed (default: 0.1)
--timer SECONDS         Run for specified duration
--once                  Single pass through characters
--show                  Print characters with codepoints (no animation)
--interactive, -i [START]  Interactive Unicode browser (default: 0xAB20)
-h, --help              Show help message
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
