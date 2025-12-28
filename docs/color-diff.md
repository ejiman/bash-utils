# color-diff

Show colorized diff between two files with optional JSON key sorting.

## Synopsis

```bash
color-diff [options] <file1> <file2>
```

## Description

`color-diff` is a wrapper around the `diff` command that provides colorized output and special handling for JSON files. When comparing JSON files, it can optionally sort keys before comparison to ignore ordering differences.

## Options

- `-j, --json` - Enable JSON mode (requires `jq`)
  - Sorts keys recursively before comparison
  - Ignores key ordering differences
- `-c, --context <N>` - Number of context lines to show (default: 3)
- `-h, --help` - Show help message
- `-v, --version` - Show version information

## Exit Status

- `0` - Files are identical
- `1` - Files differ
- `2` - Error occurred (e.g., file not found, invalid arguments)

## Examples

### Basic Usage

Compare two text files:

```bash
color-diff file1.txt file2.txt
```

### JSON Comparison

Compare JSON files with key sorting:

```bash
color-diff --json config1.json config2.json
color-diff -j api-response1.json api-response2.json
```

This is particularly useful when comparing JSON files where the same data might have keys in different orders:

```json
# file1.json
{"name": "John", "age": 30}

# file2.json
{"age": 30, "name": "John"}

# Without --json: shows difference (key order)
# With --json: no difference (semantically identical)
```

### Custom Context Lines

Show more or less context around differences:

```bash
# Show 5 lines of context
color-diff --context 5 file1.txt file2.txt

# Show minimal context (1 line)
color-diff -c 1 file1.txt file2.txt

# Show no context (differences only)
color-diff -c 0 file1.txt file2.txt
```

## Requirements

### Core Requirements

- `diff` command with color support
  - Linux: Usually built-in (GNU diffutils)
  - macOS: Built-in (BSD diff)

### Optional Requirements

- `jq` - Required for `--json` mode
  - Linux: `apt install jq` or `yum install jq`
  - macOS: `brew install jq`

## Tips

### Using in Scripts

```bash
#!/usr/bin/env bash

if color-diff expected.txt actual.txt > /dev/null 2>&1; then
  echo "Files match!"
else
  echo "Files differ:"
  color-diff expected.txt actual.txt
fi
```

### Comparing API Responses

```bash
# Fetch and compare API responses
curl -s "https://api.example.com/v1/data" > response1.json
curl -s "https://api.example.com/v2/data" > response2.json
color-diff -j response1.json response2.json
```

### Pre-commit Hook

```bash
# Check if configuration files have changed
if ! color-diff -j .config.json.backup .config.json; then
  echo "Configuration has been modified"
fi
```

## Known Limitations

- JSON mode requires `jq` to be installed
- Very large files may take time to process in JSON mode
- Color output may not work in all terminal emulators

## See Also

- [generate-release-notes](generate-release-notes.md) - Generate release notes from git commits
- [slack-post](slack-post.md) - Post messages to Slack
