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
| `-s` | `--series` | Series name | `sample` | `-s jobs` |
| `-l` | `--lang` | Language code | `ja` | `-l en` |
| `-d` | `--dir` | Data directory | `~/.config/kakugen/`| `-d /path/to/data` |

### Setting up to run on terminal startup

To display a quote every time you open a new terminal, add the command to the end of your `~/.zshrc` (or `~/.bashrc`):

```bash
# In ~/.zshrc
/path/to/kakugen/kakugen.sh
```

If you moved it to your path:
```bash
kakugen -n 1 -l en
```

## Adding Custom Quotes

Quotes are stored in plain text files.
1. Create a file named `<series>_<lang>.txt` (e.g., `zen_en.txt`).
2. Write one quote per line.
3. Blank lines or lines starting with `#` are ignored.
4. Place the file in `~/.config/kakugen/`.
