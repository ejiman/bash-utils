# github-get-project-field-id

Get GitHub project field ID from field name.

## Synopsis

```bash
# Get all fields from a project by ID
github-get-project-field-id --project-id <project-id>

# Get all fields from a project by org and number
github-get-project-field-id --org <org> --number <number>

# Filter by field name
github-get-project-field-id --org <org> --number <number> --field-name <name>
```

## Description

`github-get-project-field-id` retrieves field information from GitHub Projects (Projects V2) using the GitHub CLI (`gh`) and GraphQL API. It helps you find field IDs which are required for updating project items via API or automation workflows.

This tool supports filtering by field name and multiple output formats (table, JSON, or ID-only) for easy integration with scripts and CI/CD pipelines.

## Options

- `-p, --project-id <id>` - Project node ID (e.g., `PVT_kwDOABCDEF`)
  - Use this when you already know the project's node ID
- `-o, --org <org>` - Organization name (requires `--number`)
  - The GitHub organization or user that owns the project
- `-n, --number <num>` - Project number (requires `--org`)
  - The project number visible in the GitHub UI
- `-f, --field-name <name>` - Filter by field name (case-insensitive partial match)
  - Filters the results to fields whose names contain the specified string
- `--format <format>` - Output format: `table`, `json`, `id-only` (default: `table`)
  - `table`: Human-readable table format
  - `json`: JSON format for programmatic use
  - `id-only`: Output only field IDs (or name:id pairs if no filter)
- `-V, --verbose` - Enable verbose output
- `-h, --help` - Show help message
- `-v, --version` - Show version information

## Requirements

### Core Requirements

- `gh` (GitHub CLI) - [Installation guide](https://cli.github.com/)
- `jq` - JSON processor
- Authenticated GitHub CLI session (`gh auth login`)

### Permissions

The authenticated user must have read access to the specified GitHub project.

## Examples

### Get All Fields from a Project

Using project ID:

```bash
github-get-project-field-id --project-id PVT_kwDOABCDEF
```

Using organization and project number:

```bash
github-get-project-field-id --org myorg --number 1
```

Example output:

```
FIELD_NAME  FIELD_ID                        TYPE                          ADDITIONAL_INFO
----------  --------                        ----                          ---------------
Title       PVTF_lADOANN5s84ACbL0zgBZrZY    ProjectV2Field                -
Status      PVTSSF_lADOANN5s84ACbL0zgBZrZg  ProjectV2SingleSelectField    Options: 3
Priority    PVTSSF_lADOANN5s84ACbL0zgBZrZk  ProjectV2SingleSelectField    Options: 4
Sprint      PVTIF_lADOANN5s84ACbL0zgBah28   ProjectV2IterationField       Iterations: 6
```

### Filter by Field Name

Find fields matching "status" (case-insensitive):

```bash
github-get-project-field-id --org myorg --number 1 --field-name status
```

Example output:

```
FIELD_NAME  FIELD_ID                        TYPE                          ADDITIONAL_INFO
----------  --------                        ----                          ---------------
Status      PVTSSF_lADOANN5s84ACbL0zgBZrZg  ProjectV2SingleSelectField    Options: 3
```

### Get Field ID Only (for Scripting)

```bash
FIELD_ID=$(github-get-project-field-id --org myorg --number 1 --field-name status --format id-only)
echo "Status field ID: $FIELD_ID"
```

Example output:

```
Status field ID: PVTSSF_lADOANN5s84ACbL0zgBZrZg
```

### JSON Output

Get all fields as JSON:

```bash
github-get-project-field-id --org myorg --number 1 --format json
```

Example output:

```json
[
  {
    "__typename": "ProjectV2Field",
    "id": "PVTF_lADOANN5s84ACbL0zgBZrZY",
    "name": "Title",
    "dataType": "TEXT"
  },
  {
    "__typename": "ProjectV2SingleSelectField",
    "id": "PVTSSF_lADOANN5s84ACbL0zgBZrZg",
    "name": "Status",
    "dataType": "SINGLE_SELECT",
    "options": [
      {
        "id": "f75ad846",
        "name": "Todo"
      },
      {
        "id": "47fc9ee4",
        "name": "In Progress"
      },
      {
        "id": "98236657",
        "name": "Done"
      }
    ]
  }
]
```

### Use in Automation

Update a project item's field value using the retrieved field ID:

```bash
#!/bin/bash
set -euo pipefail

ORG="myorg"
PROJECT_NUMBER=1
ITEM_ID="PVTI_lADOANN5s84ACbL0zgBkd1M"

# Get the Status field ID
STATUS_FIELD_ID=$(github-get-project-field-id \
  --org "$ORG" \
  --number "$PROJECT_NUMBER" \
  --field-name "status" \
  --format id-only)

# Get the option ID for "In Progress"
OPTION_ID=$(gh api graphql -f query='
  query($org: String!, $number: Int!) {
    organization(login: $org) {
      projectV2(number: $number) {
        fields(first: 100) {
          nodes {
            ... on ProjectV2SingleSelectField {
              id
              name
              options {
                id
                name
              }
            }
          }
        }
      }
    }
  }' -f org="$ORG" -F number="$PROJECT_NUMBER" \
  | jq -r '.data.organization.projectV2.fields.nodes[]
    | select(.name == "Status")
    | .options[]
    | select(.name == "In Progress")
    | .id')

# Update the item status
gh api graphql -f query='
  mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $optionId: String!) {
    updateProjectV2ItemFieldValue(
      input: {
        projectId: $projectId
        itemId: $itemId
        fieldId: $fieldId
        value: { singleSelectOptionId: $optionId }
      }
    ) {
      projectV2Item {
        id
      }
    }
  }' \
  -f projectId="PVT_kwDOABCDEF" \
  -f itemId="$ITEM_ID" \
  -f fieldId="$STATUS_FIELD_ID" \
  -f optionId="$OPTION_ID"

echo "Updated item status to 'In Progress'"
```

## Field Types

GitHub Projects V2 supports several field types:

- **ProjectV2Field**: Basic fields (Text, Number, Date)
- **ProjectV2SingleSelectField**: Dropdown fields with predefined options
- **ProjectV2IterationField**: Sprint/iteration fields with date ranges

The tool displays additional information for special field types:
- For `ProjectV2SingleSelectField`: Shows the number of available options
- For `ProjectV2IterationField`: Shows the number of iterations

## Finding Your Project Information

### Method 1: Using Project Node ID

You can find the project node ID in the GitHub UI:

1. Navigate to your project
2. Click on the "..." menu
3. Select "Settings"
4. The URL will contain the project ID, e.g., `https://github.com/orgs/ORGNAME/projects/123/settings`
5. Or use `gh` to get the node ID:

```bash
gh api graphql -f query='
  query($org: String!, $number: Int!) {
    organization(login: $org) {
      projectV2(number: $number) {
        id
        title
      }
    }
  }' -f org="YOUR_ORG" -F number=1
```

### Method 2: Using Organization and Project Number

The project number is visible in the project URL:

```
https://github.com/orgs/ORGNAME/projects/123
                                          ^^^
                                    Project number
```

## Tips

### Quickly Find Field IDs for a New Project

When you need to set up automation for a new project, start by listing all fields:

```bash
github-get-project-field-id --org myorg --number 1
```

Then save the field IDs you need as environment variables or in a configuration file.

### Integration with CI/CD

This tool is designed to work well in CI/CD pipelines:

```yaml
# GitHub Actions example
- name: Get field IDs
  run: |
    STATUS_FIELD=$(github-get-project-field-id \
      --org ${{ github.repository_owner }} \
      --number 1 \
      --field-name "status" \
      --format id-only)
    echo "STATUS_FIELD=$STATUS_FIELD" >> $GITHUB_ENV
```

### Verbose Mode for Debugging

Use `-V` or `--verbose` to see detailed information about API calls:

```bash
github-get-project-field-id --org myorg --number 1 -V
```

## Known Limitations

- Only retrieves the first 100 fields from a project (GitHub API limitation)
- Requires authenticated GitHub CLI session
- The tool does not cache results; each invocation makes a fresh API call

## See Also

- [github-get-project-info](github-get-project-info.md) - Get GitHub project information and configuration
- [GitHub Projects V2 API Documentation](https://docs.github.com/en/issues/planning-and-tracking-with-projects/automating-your-project/using-the-api-to-manage-projects)
- [GitHub CLI Manual](https://cli.github.com/manual/)
