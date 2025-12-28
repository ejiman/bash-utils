# generate-release-notes

Generate release notes from git commits using conventional commit format.

## Synopsis

```bash
generate-release-notes [options]
```

## Description

`generate-release-notes` analyzes git commit history and generates formatted release notes based on conventional commit messages. It groups commits by type (features, bug fixes, etc.) and formats them into a human-readable changelog.

## Options

- `--from <ref>` - Starting git reference (tag, branch, or commit)
  - Default: Latest git tag
- `--to <ref>` - Ending git reference (tag, branch, or commit)
  - Default: `HEAD`
- `-o, --output <file>` - Output file path
  - Default: Print to stdout
- `-h, --help` - Show help message
- `-v, --version` - Show version information

## Conventional Commit Format

The tool recognizes the following commit types:

- `feat:` - New features
- `fix:` - Bug fixes
- `docs:` - Documentation changes
- `style:` - Code style changes (formatting, etc.)
- `refactor:` - Code refactoring
- `perf:` - Performance improvements
- `test:` - Test additions or modifications
- `build:` - Build system changes
- `ci:` - CI/CD changes
- `chore:` - Other changes (maintenance, etc.)

## Examples

### Generate from Latest Tag

Generate release notes from the latest tag to HEAD:

```bash
generate-release-notes
```

Output example:
```
## Features
- Add dark mode support
- Implement user preferences API

## Bug Fixes
- Fix memory leak in data processor
- Correct timezone handling

## Documentation
- Update API documentation
- Add migration guide
```

### Specify Version Range

Generate release notes between specific versions:

```bash
generate-release-notes --from v1.0.0 --to v2.0.0
```

### Save to File

Save release notes to a file:

```bash
generate-release-notes --output RELEASE_NOTES.md
```

### Compare Branches

Compare changes between branches:

```bash
generate-release-notes --from main --to develop
```

### Preview Next Release

See what will be in the next release:

```bash
# From latest tag to current HEAD
generate-release-notes

# Or explicitly
generate-release-notes --from $(git describe --tags --abbrev=0) --to HEAD
```

## Usage in Release Workflow

### Manual Release

```bash
# Generate release notes
generate-release-notes --output RELEASE_NOTES.md

# Review and edit if needed
vim RELEASE_NOTES.md

# Create release
gh release create v1.2.0 --notes-file RELEASE_NOTES.md
```

### Automated Release

```bash
#!/usr/bin/env bash
VERSION="v1.2.0"

# Generate release notes
generate-release-notes --output /tmp/release-notes.md

# Create tag
git tag -a "$VERSION" -m "Release $VERSION"
git push origin "$VERSION"

# Create GitHub release
gh release create "$VERSION" --notes-file /tmp/release-notes.md
```

### Integration with release.sh

The `release.sh` script in this project automatically uses `generate-release-notes`:

```bash
./release.sh patch  # Automatically generates release notes
```

## Commit Message Best Practices

For best results, follow conventional commit format:

```
<type>: <description>

[optional body]

[optional footer]
```

### Good Examples

```
feat: add user authentication system

Implements JWT-based authentication with refresh tokens.
Includes login, logout, and token refresh endpoints.

Closes #123
```

```
fix: resolve memory leak in cache manager

The cache was not properly clearing expired entries,
causing memory usage to grow unbounded.
```

```
docs: update installation instructions

Add troubleshooting section for common macOS issues.
```

### Examples to Avoid

```
# Too vague
update stuff

# Missing type
added new feature for users

# Not descriptive
fix bug
```

## Requirements

- Git repository with commit history
- Git tags (for default `--from` behavior)

## Tips

### Grouping Related Changes

Use commit scope for better organization:

```
feat(auth): add OAuth2 support
feat(api): add rate limiting
fix(auth): correct token expiration
```

The tool will still group by type, but scopes help readers understand context.

### Breaking Changes

Mark breaking changes in commit footer:

```
feat: change API response format

BREAKING CHANGE: Response now uses camelCase instead of snake_case
```

### Filtering Commits

The tool only includes commits with recognized types. Regular commits without a type prefix are excluded from release notes.

## See Also

- [Conventional Commits](https://www.conventionalcommits.org/) - Commit message convention
- [color-diff](color-diff.md) - Compare files with color output
- [slack-post](slack-post.md) - Post messages to Slack
