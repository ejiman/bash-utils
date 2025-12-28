# github-get-project-info

Get GitHub Project v2 information (project ID, item ID, field IDs) from an issue number.

## Synopsis

```bash
github-get-project-info [options] <issue-number>
```

## Description

`github-get-project-info` retrieves detailed information about GitHub Projects (v2) associated with a specific issue. It uses the GitHub GraphQL API to fetch project IDs, item IDs, and custom field information, which are useful for automating project board operations.

This tool automatically detects the repository owner and name from the git remote if run within a git repository, or you can specify them manually with options.

## Options

- `-o, --owner <owner>` - Repository owner (auto-detected if in git repo)
- `-r, --repo <repo>` - Repository name (auto-detected if in git repo)
- `-f, --format <format>` - Output format: `text` or `json` (default: `text`)
- `-V, --verbose` - Enable verbose output
- `-h, --help` - Show help message
- `-v, --version` - Show version information

## Exit Status

- `0` - Success
- `1` - Error occurred (issue not found, API error, etc.)

## Examples

### Basic Usage

Run in a git repository to automatically detect owner and repo:

```bash
github-get-project-info 123
```

Output:
```
Repository: owner/repo
Issue: #123 - Issue title

Found 1 project(s):

Project #1: My Project
  Project ID: PVT_kwDOABCDEF
  Item ID: PVTI_lADOABCDEFzgABCDE

  Custom Fields:
    - Status (ID: PVTF_lADOABCDEF): In Progress
    - Priority (ID: PVTF_lADOABCDEG): High
    - Sprint (ID: PVTF_lADOABCDEH): Sprint 5
```

### Specify Repository Manually

```bash
github-get-project-info --owner octocat --repo hello-world 42
```

### JSON Output

For scripting and automation:

```bash
github-get-project-info --format json 123
```

Output:
```json
{
  "data": {
    "repository": {
      "issue": {
        "title": "Add new feature",
        "projectItems": {
          "nodes": [
            {
              "id": "PVTI_lADOABCDEFzgABCDE",
              "project": {
                "id": "PVT_kwDOABCDEF",
                "title": "My Project",
                "number": 1
              },
              "fieldValues": {
                "nodes": [
                  {
                    "name": "In Progress",
                    "field": {
                      "id": "PVTF_lADOABCDEF",
                      "name": "Status"
                    }
                  }
                ]
              }
            }
          ]
        }
      }
    }
  }
}
```

### Extract Specific Values with jq

Get only the project ID:

```bash
github-get-project-info --format json 123 | \
  jq -r '.data.repository.issue.projectItems.nodes[0].project.id'
```

Get only the item ID:

```bash
github-get-project-info --format json 123 | \
  jq -r '.data.repository.issue.projectItems.nodes[0].id'
```

Get a specific field ID by name:

```bash
github-get-project-info --format json 123 | \
  jq -r '.data.repository.issue.projectItems.nodes[0].fieldValues.nodes[] | select(.field.name == "Status") | .field.id'
```

### Verbose Mode

Show detailed logging:

```bash
github-get-project-info --verbose 123
```

## Use Cases

### Updating Project Field Values

Use the retrieved IDs to update project fields via GraphQL API:

```bash
# Get project information
INFO=$(github-get-project-info --format json 123)

# Extract IDs
PROJECT_ID=$(echo "$INFO" | jq -r '.data.repository.issue.projectItems.nodes[0].project.id')
ITEM_ID=$(echo "$INFO" | jq -r '.data.repository.issue.projectItems.nodes[0].id')
FIELD_ID=$(echo "$INFO" | jq -r '.data.repository.issue.projectItems.nodes[0].fieldValues.nodes[] | select(.field.name == "Status") | .field.id')

# Update the field (example mutation)
gh api graphql -f query='
  mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $value: String!) {
    updateProjectV2ItemFieldValue(
      input: {
        projectId: $projectId
        itemId: $itemId
        fieldId: $fieldId
        value: { singleSelectOptionId: $value }
      }
    ) {
      projectV2Item {
        id
      }
    }
  }
' -f projectId="$PROJECT_ID" -f itemId="$ITEM_ID" -f fieldId="$FIELD_ID" -f value="OPTION_ID"
```

### CI/CD Integration

Automatically update project boards based on issue status:

```bash
#!/bin/bash
# Update project status when issue is closed

ISSUE_NUMBER=$1

# Get project information
PROJECT_INFO=$(github-get-project-info --format json "$ISSUE_NUMBER")

# Extract necessary IDs
ITEM_ID=$(echo "$PROJECT_INFO" | jq -r '.data.repository.issue.projectItems.nodes[0].id')

# Update status to "Done"
# (implementation depends on your project configuration)
```

### Batch Processing

Process multiple issues:

```bash
#!/bin/bash
# Check project status for multiple issues

for issue in 10 20 30 40; do
  echo "Issue #$issue:"
  github-get-project-info "$issue"
  echo ""
done
```

## Requirements

### Core Requirements

- `gh` - GitHub CLI (for GraphQL API access)
- `jq` - JSON processor

### Installation

**GitHub CLI (gh):**

```bash
# macOS
brew install gh

# Linux (Debian/Ubuntu)
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh
```

**jq:**

```bash
# macOS
brew install jq

# Linux (Debian/Ubuntu)
sudo apt install jq
```

### Authentication

You must authenticate with GitHub CLI with the required scopes.

**Initial authentication** (if not logged in):

```bash
gh auth login -s read:project
```

**Add scopes to existing authentication**:

```bash
gh auth refresh -s read:project
```

**Verify authentication**:

```bash
gh auth status
```

**Required scopes**:
- `repo` - Full control of private repositories (automatically included)
- `read:project` - Read access to projects (required for this tool)

## Tips

### Handling Multiple Projects

If an issue is associated with multiple projects, the output will include all of them. Use array indexing with jq to access specific projects:

```bash
# Get the second project's ID
github-get-project-info --format json 123 | \
  jq -r '.data.repository.issue.projectItems.nodes[1].project.id'
```

### Repository Auto-Detection

The tool detects repository information from the git remote URL. It supports both HTTPS and SSH formats:

- HTTPS: `https://github.com/owner/repo.git`
- SSH: `git@github.com:owner/repo.git`

### Error Handling

If the API returns errors, they will be displayed with details:

```bash
github-get-project-info 9999
# Output: GraphQL API returned errors:
#   - Could not resolve to an Issue with the number of 9999.
```

## Known Limitations

- Maximum 10 projects per issue (can be increased by modifying the GraphQL query)
- Maximum 50 field values per project item (can be increased by modifying the GraphQL query)
- Requires GitHub CLI authentication
- Only works with GitHub Projects v2 (not classic projects)

## See Also

- [slack-post](slack-post.md) - Post messages to Slack (useful for notifications)
- [generate-release-notes](generate-release-notes.md) - Generate release notes from git commits
- [GitHub GraphQL API Documentation](https://docs.github.com/en/graphql)
- [GitHub Projects v2 Documentation](https://docs.github.com/en/issues/planning-and-tracking-with-projects)
