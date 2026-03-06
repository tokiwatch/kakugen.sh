# Kakugen (Maxims) CLI

Kakugen is a simple command-line application that displays random quotes or maxims every time you open a new terminal session.

## Features

- **Fast**: Written in a lightweight bash script, so it adds practically zero overhead to your terminal startup time.
- **Dependency-Free**: Uses standard UNIX tools (`shuf` or `awk`, `grep`).
- **Customizable**: Add your own series of quotes in different languages.

## Installation

1. Clone or download this repository.
2. Make the script executable:

   ```bash
   chmod +x kakugen.sh
   ```

3. (Optional) Move the script to a directory in your `$PATH` (e.g., `/usr/local/bin/` or `~/bin/`) to use it simply as `kakugen`.
   ```bash
   sudo cp kakugen.sh /usr/local/bin/kakugen
   ```

4. Place your data files in `~/.config/kakugen/` (or keep them in the same directory as the script).
   ```bash
   mkdir -p ~/.config/kakugen
   cp sample_ja.txt ~/.config/kakugen/
   cp sample_en.txt ~/.config/kakugen/
   ```

## Usage

Run the script to display a quote:

```bash
./kakugen.sh
```

### Options

| Short | Long | Description | Default | Example |
|---|---|---|---|---|
| `-n` | `--number` | Number of quotes to display | `1` | `-n 3` |
| `-f` | `--file` | File paths to read (comma-separated). Overrides config. | None | `-f quotes.txt` |
| `-c` | `--config` | Path to configuration file | `~/.kakugenrc` | `-c ~/.myrc` |
| `-s` | `--search` | Filter quotes by a specific substring | None | `-s "Rome"` |

### Configuration File (`~/.kakugenrc`)

By default, Kakugen reads the file paths listed in `~/.kakugenrc`. Create this file to specify which quote files you want to include in the random selection.

> **Note**: When multiple text files are loaded (either via config or the `-f` option), the source filename (without extension, e.g., `-- sample_ja`) is automatically appended to each quote to indicate its origin.

You can customize the displayed title by appending `=Your Custom Title` to the file path in `.kakugenrc`.

**Example `~/.kakugenrc`:**
```text
# Lines starting with # are comments
~/.config/kakugen/sample_ja.txt=Japanese Proverbs
~/.config/kakugen/sample_en.txt=English Quotes
```

### Setting up to run on terminal startup

To display a quote every time you open a new terminal, add the command to the end of your `~/.zshrc` (or `~/.bashrc`):

```bash
# In ~/.zshrc
/path/to/kakugen/kakugen.sh
```

If you moved it to your path:
```bash
kakugen -n 1
```

## Adding Custom Quotes

Quotes are stored in plain text files and are separated by a line containing only a **`%`** symbol. This allows for multi-line quotes.

1. Create a text file.
2. Separate each quote using a line with just `%`.
3. Add the path of your new file to `~/.kakugenrc`.

**Example data file:**
```text
Rome wasn't built in a day.
%
Perseverance will win in the end.
(Japanese proverb)
%
A journey of a thousand miles begins with a single step.
- Laozi
%
```
