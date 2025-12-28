# github-add-sub-issues

Add existing GitHub issues as sub-issues to a parent issue using GitHub's native sub-issue feature.

## Synopsis

```bash
github-add-sub-issues [options] <parent-issue> <sub-issue>...
```

## Description

This tool adds one or more existing GitHub issues as sub-issues to a parent issue using GitHub's REST API sub-issue functionality. Sub-issues create a parent-child relationship between issues, making it easier to track dependencies and organize work hierarchically.

Unlike adding tasklist items to the issue body, this tool uses GitHub's native sub-issue feature, which provides:
- Automatic progress tracking in the GitHub UI
- Visual hierarchy in issue listings
- Proper parent-child relationships via the API

## Options

- `-V, --verbose` - Enable verbose output to see detailed progress information
- `-f, --force` - Replace existing parent if a sub-issue already has one (uses `replace_parent: true` in API call)
- `-R, --repo OWNER/REPO` - Specify the repository in 'owner/repo' format (default: current repository)
- `-h, --help` - Show help message and exit
- `-v, --version` - Show version information and exit

## Exit Status

- `0` - Success
- `1` - Error occurred (authentication failed, issue not found, API error, etc.)

## Examples

### Basic Usage

Add single sub-issue to a parent issue:

```bash
github-add-sub-issues 100 101
```

This adds issue #101 as a sub-issue of issue #100.

### Add Multiple Sub-issues

Add multiple issues as sub-issues to a parent:

```bash
github-add-sub-issues 100 101 102 103
```

This adds issues #101, #102, and #103 as sub-issues of issue #100.

### Specify Repository

Add sub-issues in a specific repository:

```bash
github-add-sub-issues --repo octocat/Hello-World 100 101 102
```

### Replace Existing Parent

If a sub-issue already has a parent, you can force it to be reassigned:

```bash
github-add-sub-issues --force 100 101
```

### Verbose Output

See detailed information about the process:

```bash
github-add-sub-issues --verbose 100 101 102
```

Example output:
```
[INFO] Parent issue: #100
[INFO] Sub-issues: 101 102
[INFO] Fetching ID for issue #101...
[INFO] Issue #101 has ID: 1234567890
[INFO] Fetching ID for issue #102...
[INFO] Issue #102 has ID: 1234567891
[INFO] Adding issue #101 as sub-issue to #100...
[INFO] Successfully added #101
[INFO] Adding issue #102 as sub-issue to #100...
[INFO] Successfully added #102
[INFO] Successfully added 2 sub-issue(s) to #100
[INFO] View at: https://github.com/owner/repo/issues/100
```

## Requirements

### Core Requirements

- `gh` (GitHub CLI) - Must be installed and authenticated
- `bash` 4.0 or later
- Internet connection to access GitHub API

### Authentication

You must authenticate with GitHub CLI before using this tool:

```bash
# Authenticate with GitHub
gh auth login

# Verify authentication
gh auth status
```

## How It Works

1. **Validates Arguments**: Checks that at least a parent issue and one sub-issue are provided
2. **Checks Authentication**: Verifies that GitHub CLI is authenticated
3. **Validates Issues**: Confirms that all specified issues exist in the repository
4. **Fetches Issue IDs**: Retrieves the internal GitHub ID for each sub-issue (not the issue number)
5. **Calls GitHub API**: Uses `POST /repos/{owner}/{repo}/issues/{issue_number}/sub_issues` endpoint to create sub-issue relationships
6. **Reports Results**: Shows success/failure for each sub-issue and provides a link to view the parent issue

## API Details

This tool uses the following GitHub REST API endpoint:

```
POST /repos/{owner}/{repo}/issues/{issue_number}/sub_issues
```

Request body:
```json
{
  "sub_issue_id": 1234567890,
  "replace_parent": false
}
```

The `sub_issue_id` is the internal GitHub ID (not the issue number), which is automatically fetched by the tool.

## Error Handling

The tool handles various error cases:

- **Not authenticated**: Shows error message and suggests running `gh auth login`
- **Issue not found**: Shows which issue number does not exist
- **API errors**: Reports failures for individual sub-issues but continues processing others
- **Missing arguments**: Shows usage information

## Tips

### Organizing Large Projects

Use sub-issues to break down epic issues into smaller, manageable tasks:

```bash
# Create epic issue
gh issue create --title "Epic: Implement new feature" --body "..."

# Create sub-task issues
gh issue create --title "Design API" --body "..."
gh issue create --title "Implement backend" --body "..."
gh issue create --title "Create frontend" --body "..."
gh issue create --title "Write tests" --body "..."

# Link them as sub-issues (assuming epic is #100 and tasks are #101-104)
github-add-sub-issues 100 101 102 103 104
```

### CI/CD Integration

Automatically create sub-issues from a project management tool:

```bash
#!/bin/bash
# Example: Create sub-issues from a JSON file

parent_issue=$(jq -r '.parent' tasks.json)
sub_issues=$(jq -r '.tasks[].issue_number' tasks.json | tr '\n' ' ')

github-add-sub-issues "$parent_issue" $sub_issues
```

### Scripting with Error Handling

```bash
#!/bin/bash
set -e

parent=100
subs=(101 102 103)

if github-add-sub-issues --verbose "$parent" "${subs[@]}"; then
  echo "All sub-issues added successfully!"
else
  echo "Some sub-issues failed to add. Check the output above."
  exit 1
fi
```

## Known Limitations

- **Repository-scoped**: All issues must be in the same repository (parent and sub-issues)
- **Requires GitHub API access**: Must have appropriate permissions in the repository
- **No cross-repository sub-issues**: GitHub's sub-issue feature does not support linking issues across different repositories
- **Rate limiting**: Creating many sub-issues quickly may trigger GitHub's rate limiting

## See Also

- [GitHub CLI Documentation](https://cli.github.com/manual/)
- [GitHub REST API: Sub-issues](https://docs.github.com/en/rest/issues/sub-issues)
- [github-create-issues](github-create-issues.md) - Create multiple GitHub issues from a file
