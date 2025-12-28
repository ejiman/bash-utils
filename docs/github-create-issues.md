# github-create-issues

Create multiple GitHub issues from JSON input with support for labels, assignees, milestones, and templates.

## Synopsis

```bash
# From stdin
echo '[{"title":"Bug","body":"Fix"}]' | github-create-issues

# From file
github-create-issues -i issues.json

# With options
github-create-issues -i issues.json -l bug,urgent -p "Project Name" --dry-run
```

## Description

`github-create-issues` is a tool for bulk creating GitHub issues from JSON input. It supports reading from stdin or a file, applying default labels/assignees/milestones, using GitHub issue templates, and dry-run mode for previewing changes before execution.

This tool is particularly useful for:
- Migrating issues from other systems
- Creating multiple related issues from a template
- Automating issue creation in CI/CD pipelines
- Batch operations on GitHub repositories

## Options

- `-i, --input <file>` - JSON input file (default: stdin)
- `-t, --template <name>` - GitHub issue template name (e.g., `bug_report.md`)
- `-l, --labels <labels>` - Default labels, comma-separated (e.g., `bug,priority-high`)
- `-p, --project <name>` - Add issues to GitHub project
- `-m, --milestone <number>` - Default milestone number
- `-a, --assignees <users>` - Default assignees, comma-separated
- `-r, --repo <owner/repo>` - Target repository (default: current repo)
- `-n, --dry-run` - Show what would be created without actually creating
- `-V, --verbose` - Enable verbose output
- `-h, --help` - Show help message
- `-v, --version` - Show version information

## JSON Input Format

### Single Issue

```json
{
  "title": "Issue title",
  "body": "Issue description",
  "labels": ["bug", "enhancement"],
  "assignees": ["username1", "username2"],
  "milestone": 5,
  "template": "bug_report.md"
}
```

### Multiple Issues

```json
[
  {
    "title": "First issue",
    "body": "Description of first issue"
  },
  {
    "title": "Second issue",
    "body": "Description of second issue",
    "labels": ["bug"]
  }
]
```

### Field Descriptions

- **title** (required): The issue title
- **body** (optional): The issue description/body
- **labels** (optional): Array of label names
- **assignees** (optional): Array of GitHub usernames
- **milestone** (optional): Milestone number (integer)
- **template** (optional): Issue template filename

## Examples

### Basic Usage

Create issues from JSON file:

```bash
# Create issues.json
cat > issues.json << 'EOF'
[
  {
    "title": "Add login feature",
    "body": "Implement user authentication",
    "labels": ["enhancement", "priority-high"]
  },
  {
    "title": "Fix navigation bug",
    "body": "Navigation bar doesn't work on mobile",
    "labels": ["bug"]
  }
]
EOF

# Create the issues
github-create-issues -i issues.json
```

### Using Stdin

```bash
echo '[{"title":"Quick issue","body":"Description"}]' | github-create-issues
```

### With Default Labels

Apply labels to all issues:

```bash
github-create-issues -i issues.json -l bug,needs-review
```

Per-issue labels will be merged with default labels:

```json
[
  {
    "title": "Issue 1",
    "labels": ["critical"]
  }
]
```

With `-l bug`, this creates an issue with labels: `bug,critical`

### Using Issue Templates

Specify a GitHub issue template:

```bash
github-create-issues -i issues.json -t bug_report.md
```

Per-issue template overrides default:

```json
[
  {
    "title": "Bug report",
    "template": "bug_report.md"
  },
  {
    "title": "Feature request",
    "template": "feature_request.md"
  }
]
```

### Assigning to Users

```bash
github-create-issues -i issues.json -a user1,user2
```

### Adding to Project

```bash
github-create-issues -i issues.json -p "Sprint 2024-Q1"
```

### Setting Milestone

```bash
github-create-issues -i issues.json -m 3
```

### Dry Run

Preview what would be created without actually creating:

```bash
github-create-issues -i issues.json --dry-run
```

Output:
```
[INFO] Found 2 issue(s) to create
─────────────────────────────────────
Would create issue #1:
  Title: Add login feature
  Body: Implement user authentication...
  Labels: enhancement,priority-high
─────────────────────────────────────
Would create issue #2:
  Title: Fix navigation bug
  Body: Navigation bar doesn't work on mobile...
  Labels: bug
[INFO] Dry run completed. No issues were created.
```

### Verbose Mode

```bash
github-create-issues -i issues.json -V --dry-run
```

Shows additional information including the exact `gh` commands that would be executed.

### Target Different Repository

```bash
github-create-issues -i issues.json -r owner/other-repo
```

## CI/CD Integration

### GitHub Actions

```yaml
name: Create Issues

on:
  workflow_dispatch:
    inputs:
      issues_file:
        description: 'Path to issues JSON file'
        required: true

jobs:
  create-issues:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup GitHub CLI
        run: |
          gh auth status || gh auth login --with-token <<< "${{ secrets.GITHUB_TOKEN }}"

      - name: Install github-create-issues
        run: |
          curl -sL https://github.com/your-org/bash-utils/releases/latest/download/bash-utils.tar.gz | tar xz
          cd bash-utils-*
          sudo ./install.sh

      - name: Create Issues
        run: |
          github-create-issues -i "${{ github.event.inputs.issues_file }}" \
            -l automated \
            -p "Backlog"
```

### GitLab CI

```yaml
create_issues:
  stage: deploy
  script:
    - github-create-issues -i issues.json -r owner/repo
  only:
    - main
```

### Jenkins

```groovy
pipeline {
  agent any
  stages {
    stage('Create Issues') {
      steps {
        sh '''
          github-create-issues -i issues.json \
            -l jenkins,automated \
            -m 5
        '''
      }
    }
  }
}
```

## Advanced Usage

### Generating JSON from Scripts

```bash
#!/bin/bash

# Generate issues from TODOs in code
generate_todo_issues() {
  grep -r "TODO:" src/ | while IFS=: read -r file line text; do
    cat << EOF
{
  "title": "TODO: ${text#*TODO: }",
  "body": "Found in \`$file\` at line $line",
  "labels": ["technical-debt", "todo"]
}
EOF
  done | jq -s '.'
}

# Create issues
generate_todo_issues | github-create-issues -l automated
```

### Issue Migration

Migrate issues from another system:

```bash
#!/bin/bash

# Export from old system (pseudo code)
old_system export --format=json > old_issues.json

# Transform to github-create-issues format
jq '[.[] | {
  title: .subject,
  body: .description,
  labels: .tags,
  milestone: .milestone_id
}]' old_issues.json > github_issues.json

# Dry run first
github-create-issues -i github_issues.json --dry-run

# If looks good, create
github-create-issues -i github_issues.json
```

### Combining with Other Tools

```bash
# Create issues from CSV
csv2json issues.csv | \
  jq '[.[] | {title: .Title, body: .Description, labels: (.Labels | split(","))}]' | \
  github-create-issues

# Create issues from YAML
yq -o=json issues.yaml | github-create-issues
```

## Requirements

### Core Requirements

- `bash` 4.0 or later
- `gh` (GitHub CLI) - [Installation guide](https://cli.github.com/)
- `jq` - JSON processor

### GitHub CLI Authentication

You must authenticate with `gh` before using this tool:

```bash
gh auth login
```

Or use a token:

```bash
export GH_TOKEN=ghp_your_token_here
```

### Permissions

The GitHub token must have:
- `repo` scope for creating issues
- `project` scope if using `--project` option

## Exit Status

- `0` - Success
- `1` - Error occurred (invalid JSON, missing required fields, API error, etc.)

## Tips

### Planning with Dry Run

Always use `--dry-run` first to preview what will be created:

```bash
github-create-issues -i issues.json --dry-run
```

### Incremental Creation

For large batches, create issues incrementally:

```bash
# Split into chunks of 10
jq -c '.[:10]' all_issues.json | github-create-issues
jq -c '.[10:20]' all_issues.json | github-create-issues
# etc.
```

### Error Handling

The tool will stop at the first error. To continue on errors, wrap in a script:

```bash
#!/bin/bash
set +e  # Don't exit on error

github-create-issues -i issues.json
if [ $? -ne 0 ]; then
  echo "Some issues failed to create. Check logs."
fi
```

### Template Organization

Keep your issue templates organized:

```
.github/
  ISSUE_TEMPLATE/
    bug_report.md
    feature_request.md
    task.md
```

Then reference by filename:

```json
{
  "title": "Bug in login",
  "template": "bug_report.md"
}
```

### Label Management

Pre-create labels in your repository to avoid errors:

```bash
gh label create "priority-high" --color "ff0000"
gh label create "priority-medium" --color "ffaa00"
gh label create "priority-low" --color "00ff00"
```

## Known Limitations

- Cannot create issues in private repositories without proper authentication
- Rate limiting applies (GitHub API has rate limits)
- Issue templates must already exist in the repository
- Assignees must have access to the repository
- Milestone must be created beforehand

## Troubleshooting

### "gh: command not found"

Install GitHub CLI:

```bash
# macOS
brew install gh

# Linux (Debian/Ubuntu)
sudo apt install gh
```

### "jq: command not found"

Install jq:

```bash
# macOS
brew install jq

# Linux (Debian/Ubuntu)
sudo apt install jq
```

### "Invalid JSON input"

Validate your JSON:

```bash
cat issues.json | jq empty
```

### "Issue at index X is missing required field: title"

Every issue must have a `title` field:

```json
{
  "title": "This is required"
}
```

### Rate Limiting

If you hit rate limits:

```bash
gh api rate_limit
```

Wait for the reset time or use authentication to get higher limits.

## See Also

- [generate-release-notes](generate-release-notes.md) - Generate release notes from Git history
- [gh issue create](https://cli.github.com/manual/gh_issue_create) - GitHub CLI issue creation
- [jq](https://stedolan.github.io/jq/) - JSON processor
