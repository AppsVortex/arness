# Atlassian Remote MCP Server Setup

The Atlassian Remote MCP Server is the official, cloud-hosted MCP server for Jira Cloud integration. It uses OAuth 2.1 for authentication and provides native Claude Code integration for issue operations.

**Documentation:** https://support.atlassian.com/atlassian-rovo-mcp-server/docs/getting-started-with-the-atlassian-remote-mcp-server/

## Prerequisites

- A Jira Cloud instance with an active account
- Claude Code installed and running
- Project initialized with `/arn-spark-init` or `/arn-code-init` (or in the process of running it)

## Setup Procedure

### Step 1: Add the MCP Server

Run the following command from your project directory:

```bash
claude mcp add atlassian --scope project --transport http --url https://mcp.atlassian.com/v1/mcp
```

This adds the Atlassian MCP server configuration to the **project's** `.mcp.json` file (not the Arness plugin's `.mcp.json`).

### Step 2: Restart Claude Code

MCP servers are loaded at session start. After adding the server, restart Claude Code for the new server to become available:

1. Exit the current Claude Code session
2. Start a new session in the same project directory

### Step 3: Authenticate via OAuth 2.1

On the first use of any Atlassian MCP tool, a browser window will open automatically for OAuth 2.1 authentication:

1. Sign in with your Atlassian account
2. Authorize the MCP server to access your Jira instance
3. Return to Claude Code -- the session will continue with authenticated access

### Step 4: Verify the Connection

Run `/mcp` in Claude Code to confirm the Atlassian server is listed and connected:

```
/mcp
```

Look for `atlassian` in the server list with a `connected` status.

## Known Limitations

- **Re-authentication:** The OAuth 2.1 token may expire multiple times per day. When this happens, a browser window will open again for re-authentication. This is a known limitation of the Atlassian Remote MCP Server.
- **Cloud only:** The remote MCP server works with Jira Cloud only. Jira Data Center and Jira Server are not supported.
- **Scope:** The MCP server is configured per-project (`--scope project`). Each project that uses Jira integration needs its own MCP configuration.

## Notes

- The MCP server is added to the project's `.mcp.json`, not the Arness plugin's `.mcp.json`
- Arness uses the MCP server's `list_projects` tool during `/arn-spark-init` (or `/arn-code-init`) to let the user pick their Jira project
- Once configured, Arness skills (`/arn-code-create-issue`, `/arn-code-pick-issue`, `/arn-code-review-pr`) use the MCP server transparently for all Jira operations
- No API keys or tokens need to be stored in project files -- OAuth 2.1 handles authentication at runtime
