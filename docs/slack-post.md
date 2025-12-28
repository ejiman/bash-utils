# slack-post

Post messages to Slack via Incoming Webhook or Web API.

## Synopsis

```bash
# Using Incoming Webhook
slack-post [options] <message>

# Using Bot Token (Web API)
slack-post --token <token> --channel <channel> <message>
```

## Description

`slack-post` sends messages to Slack channels using either Incoming Webhooks or the Slack Web API. It supports both methods for flexibility and can read webhook URLs from environment variables for convenience.

## Options

- `-w, --webhook <url>` - Slack Incoming Webhook URL
  - Can also be set via `SLACK_WEBHOOK_URL` environment variable
- `-t, --token <token>` - Slack Bot Token (for Web API)
  - Format: `xoxb-...`
- `-c, --channel <channel>` - Slack channel ID (required with `--token`)
  - Format: `C12345678` or `#channel-name`
- `-h, --help` - Show help message
- `-v, --version` - Show version information

## Authentication Methods

### Method 1: Incoming Webhook (Recommended for Simple Use)

Incoming Webhooks are the easiest way to send messages to a specific channel.

**Setup:**
1. Go to your Slack workspace settings
2. Navigate to "Incoming Webhooks"
3. Create a new webhook for your desired channel
4. Copy the webhook URL

**Usage:**

```bash
# Direct URL specification
slack-post --webhook "https://hooks.slack.com/services/T00/B00/XXX" "Hello, World!"

# Using environment variable
export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/T00/B00/XXX"
slack-post "Hello from bash script!"
```

### Method 2: Bot Token (Web API)

Bot tokens provide more flexibility and allow posting to multiple channels.

**Setup:**
1. Create a Slack App in your workspace
2. Add the `chat:write` scope to your bot token
3. Install the app to your workspace
4. Copy the Bot User OAuth Token

**Usage:**

```bash
slack-post --token "xoxb-your-token" --channel "C12345678" "Hello via API!"
```

## Examples

### Basic Message

Send a simple message using webhook:

```bash
export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/T00/B00/XXX"
slack-post "Deployment completed successfully!"
```

### Multi-line Message

```bash
slack-post "Build Status:
- Tests: Passed
- Linting: Passed
- Deploy: Success"
```

### Using Bot Token

```bash
TOKEN="xoxb-YOUR-BOT-TOKEN"
CHANNEL="C12345678"

slack-post --token "$TOKEN" --channel "$CHANNEL" "Message from bot"
```

### CI/CD Integration

#### GitHub Actions

```yaml
- name: Notify Slack
  env:
    SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
  run: |
    slack-post "GitHub Actions: Build completed for ${{ github.ref }}"
```

#### GitLab CI

```yaml
notify:
  script:
    - slack-post "GitLab CI: Pipeline $CI_PIPELINE_ID finished"
  variables:
    SLACK_WEBHOOK_URL: $SLACK_WEBHOOK_URL
```

#### Jenkins

```groovy
stage('Notify') {
  steps {
    sh '''
      export SLACK_WEBHOOK_URL="${SLACK_WEBHOOK_URL}"
      slack-post "Jenkins: Build #${BUILD_NUMBER} completed"
    '''
  }
}
```

### Deployment Notifications

```bash
#!/usr/bin/env bash
set -euo pipefail

export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/T00/B00/XXX"

slack-post "Starting deployment to production..."

if ./deploy.sh; then
  slack-post "✅ Deployment successful!"
else
  slack-post "❌ Deployment failed!"
  exit 1
fi
```

### Monitoring Alerts

```bash
#!/usr/bin/env bash

DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')

if [ "$DISK_USAGE" -gt 80 ]; then
  slack-post "⚠️  Warning: Disk usage is at ${DISK_USAGE}%"
fi
```

### Release Announcements

```bash
#!/usr/bin/env bash
VERSION="v1.2.0"

RELEASE_NOTES=$(generate-release-notes --from v1.1.0 --to "$VERSION")

slack-post "🚀 New release: $VERSION

$RELEASE_NOTES

Download: https://github.com/user/repo/releases/tag/$VERSION"
```

## Environment Variables

- `SLACK_WEBHOOK_URL` - Default Incoming Webhook URL
  - Used when `--webhook` is not specified
  - Convenient for CI/CD environments

## Security Best Practices

### Never Commit Tokens

```bash
# ❌ Bad - Never do this
slack-post --webhook "https://hooks.slack.com/services/T00/B00/XXX" "msg"

# ✅ Good - Use environment variables
export SLACK_WEBHOOK_URL="$(cat ~/.slack-webhook)"
slack-post "msg"
```

### Use Secrets Management

```bash
# GitHub Actions
# Set SLACK_WEBHOOK_URL in repository secrets

# AWS Secrets Manager
export SLACK_WEBHOOK_URL=$(aws secretsmanager get-secret-value \
  --secret-id slack-webhook --query SecretString --output text)

# HashiCorp Vault
export SLACK_WEBHOOK_URL=$(vault kv get -field=url secret/slack/webhook)
```

### Restrict Permissions

- For webhooks: Limit to specific channels
- For bot tokens: Use minimal scopes (only `chat:write`)

## Requirements

- `curl` - For HTTP requests
  - Linux: Usually pre-installed
  - macOS: Pre-installed

## Exit Status

- `0` - Message sent successfully
- `1` - Failed to send message (network error, invalid credentials, etc.)

## Troubleshooting

### "Invalid webhook URL"

- Check that the URL starts with `https://hooks.slack.com/`
- Verify the webhook is not expired or revoked

### "Channel not found"

- Ensure the bot is added to the channel
- Verify the channel ID is correct
- For private channels, the bot must be invited

### "No message specified"

- Ensure you provide a message as an argument
- Message cannot be empty

## Tips

### Formatting Messages

Slack supports basic markdown formatting:

```bash
slack-post "*Bold text* and _italic text_
\`code\` and \`\`\`code block\`\`\`
<https://example.com|Link text>"
```

### Testing

Test your configuration:

```bash
# Test webhook
slack-post "Test message from $(hostname)"

# Test bot token
slack-post --token "$TOKEN" --channel "$CHANNEL" "Test"
```

## Limitations

- Does not support advanced message formatting (blocks, attachments)
- Does not support file uploads
- Does not support message threading
- For advanced features, use the Slack API directly or a dedicated library

## See Also

- [Slack Incoming Webhooks](https://api.slack.com/messaging/webhooks) - Official documentation
- [Slack Web API](https://api.slack.com/web) - API reference
- [color-diff](color-diff.md) - Compare files with color output
- [generate-release-notes](generate-release-notes.md) - Generate release notes
