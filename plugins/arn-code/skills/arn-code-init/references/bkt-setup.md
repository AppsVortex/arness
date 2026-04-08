# Bitbucket CLI (bkt) Setup

The `bkt` CLI provides gh-like ergonomics for Bitbucket Cloud and Data Center. Arness uses it for all Bitbucket PR operations (create, list, merge, comment).

**Repository:** https://github.com/avivsinai/bitbucket-cli

## Installation

Install `bkt` using one of the following methods:

| Method | Command |
|--------|---------|
| pipx (recommended) | `pipx install bitbucket-cli` |
| npm | `npm install -g bitbucket-cli` |
| Binary download | See [releases](https://github.com/avivsinai/bitbucket-cli/releases) |

## Authentication

Authenticate with Bitbucket using `bkt auth login`:

```bash
bkt auth login
```

This opens a browser for OAuth authentication. Follow the prompts to authorize the CLI.

### API Token (alternative)

You can also authenticate via an API token set as an environment variable:

```bash
export BKT_TOKEN="your-api-token"
```

Generate an API token from your Bitbucket account settings under **Personal settings > API tokens**.

> **Note:** Bitbucket App Passwords are deprecated as of June 2026. Use API tokens instead for new integrations.

## Verification

After installation and authentication, verify both are working:

```bash
bkt --version       # Confirm installation
bkt auth status     # Confirm authentication
```

Both commands must succeed before Arness can use Bitbucket integration.

## Notes

- `bkt` supports both Bitbucket Cloud and Bitbucket Data Center
- Arness currently targets Bitbucket Cloud only (Data Center is out of scope)
- `bkt` supports JSON and YAML output formats, which Arness uses for structured data parsing
- If `bkt` is not installed or not authenticated, Arness will skip Bitbucket platform detection during `/arn-code-init`
