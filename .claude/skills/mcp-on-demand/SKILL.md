---
name: mcp-on-demand
description: Dynamically install and use any MCP server from npm, GitHub, PyPI, or HTTP endpoints using mcptools CLI
---

# MCP On-Demand Skill

Dynamically install and use **any** MCP (Model Context Protocol) server from the internet using mcptools CLI.

## Overview

This skill enables you to:
- Install mcptools CLI if not already available
- Use ANY MCP server from npm, GitHub, PyPI, or any URL
- Discover tools, resources, and prompts from any MCP server
- Call MCP tools with parameters dynamically

## Installation

First, ensure mcptools is installed:

```bash
$CLAUDE_PROJECT_DIR/.claude/skills/mcp-on-demand/scripts/install-mcptools.sh
```

## Using Any MCP Server

mcptools can connect to **any MCP server** via multiple methods:

### From npm (any package)
```bash
# Pattern: npx -y <package-name> [args]
mcp tools npx -y <any-npm-mcp-package>

# Examples:
mcp tools npx -y @modelcontextprotocol/server-filesystem ~
mcp tools npx -y @anthropic/mcp-server-fetch
mcp tools npx -y mcp-server-sqlite ./database.db
mcp tools npx -y @org/custom-mcp-server --some-flag
```

### From GitHub (any repo)
```bash
# Clone and run directly
mcp tools npx -y github:username/repo-name

# Or clone, install, and run
git clone https://github.com/user/mcp-server.git
cd mcp-server && npm install
mcp tools node ./dist/index.js
```

### From Python/PyPI
```bash
# Using uvx (recommended)
mcp tools uvx mcp-server-package

# Using pip + python
pip install some-mcp-server
mcp tools python -m some_mcp_server

# Examples:
mcp tools uvx mcp-server-fetch
mcp tools python -m mcp_server_sqlite --db ./data.db
```

### From Local Scripts
```bash
# Node.js servers
mcp tools node /path/to/server.js

# Python servers
mcp tools python /path/to/server.py

# Any executable
mcp tools /path/to/mcp-server-binary
```

### From HTTP Endpoints
```bash
# SSE transport (auto-detected by /sse suffix)
mcp tools http://localhost:3001/sse
mcp tools https://mcp.example.com/sse

# Streamable HTTP
mcp tools https://api.example.com/mcp
```

## Core Commands

### Discover Tools
```bash
# List all tools from any server
mcp tools <server-command>

# JSON output for parsing
mcp tools -f json <server-command>

# With server logs for debugging
mcp tools --server-logs <server-command>
```

### Call Any Tool
```bash
# Pattern
mcp call <tool_name> -p '{"param": "value"}' <server-command>

# JSON output
mcp call <tool_name> -f json -p '{"params": "here"}' <server-command>
```

### Discover Resources
```bash
mcp resources <server-command>
mcp resources -f json <server-command>
```

### Discover Prompts
```bash
mcp prompts <server-command>
mcp prompts -f json <server-command>
```

## Workflow for Any MCP Server

When asked to use an MCP server:

### Step 1: Ensure mcptools is installed
```bash
if ! command -v mcp &> /dev/null && ! command -v mcptools &> /dev/null; then
    bash $CLAUDE_PROJECT_DIR/.claude/skills/mcp-on-demand/scripts/install-mcptools.sh
fi
```

### Step 2: Identify the server source
- **npm package?** → Use `npx -y <package>`
- **Python package?** → Use `uvx <package>` or `python -m <module>`
- **GitHub repo?** → Use `npx -y github:user/repo` or clone & run
- **Local file?** → Use `node/python <path>`
- **HTTP URL?** → Use URL directly

### Step 3: Discover available capabilities
```bash
# Get all tools in JSON format
mcp tools -f json <server-command>

# Check for resources
mcp resources -f json <server-command>

# Check for prompts
mcp prompts -f json <server-command>
```

### Step 4: Call tools as needed
```bash
# Call with parameters
mcp call <tool_name> -f json -p '<json_params>' <server-command>
```

## Finding MCP Servers

To find MCP servers on the internet:

### npm Registry
```bash
# Search npm for MCP servers
npm search mcp-server
npm search @modelcontextprotocol
```

### GitHub
Search GitHub for:
- `mcp-server` in repo names
- `modelcontextprotocol` topics
- Repos with MCP implementations

### Awesome MCP Lists
Common aggregations of MCP servers exist on GitHub - search for "awesome-mcp"

### Official Anthropic Servers
```bash
# List @modelcontextprotocol packages
npm search @modelcontextprotocol
```

## Output Formats

```bash
# Human-readable table (default)
mcp tools <server>

# JSON (for parsing)
mcp tools -f json <server>

# Pretty JSON
mcp tools -f pretty <server>
```

## Environment Variables

Many MCP servers need configuration via environment variables:

```bash
# Set before running
export API_KEY="your-key"
export GITHUB_TOKEN="ghp_..."
export DATABASE_URL="postgres://..."

# Then use the server
mcp tools <server-command>
```

## Advanced Features

### Server Aliases (save frequently used servers)
```bash
# Create
mcp alias add myserver npx -y @some/mcp-server --config xyz

# Use
mcp tools myserver
mcp call some_tool -p '{}' myserver
```

### Interactive Shell
```bash
# Open shell for multiple commands
mcp shell <server-command>
> tools
> call some_tool {"param": "value"}
> resources
> exit
```

### Chaining with Other Tools
```bash
# Get JSON output and process with jq
mcp call get_data -f json -p '{}' <server> | jq '.result'

# Use in scripts
RESULT=$(mcp call fetch -f json -p '{"url": "..."}' npx -y @anthropic/mcp-server-fetch)
```

## Debugging

```bash
# Show server-side logs
mcp tools --server-logs <server>

# Verbose JSON output
mcp call <tool> -f pretty --server-logs -p '{}' <server>
```

## Examples

### Use any npm MCP server
```bash
# First, discover what tools it has
mcp tools npx -y @anthropic/mcp-server-fetch

# Then call the tool
mcp call fetch -p '{"url": "https://example.com"}' npx -y @anthropic/mcp-server-fetch
```

### Use a Python MCP server
```bash
# Discover tools
mcp tools uvx mcp-server-sqlite --db-path ./test.db

# Call a tool
mcp call query -p '{"sql": "SELECT * FROM users"}' uvx mcp-server-sqlite --db-path ./test.db
```

### Use a GitHub-hosted server
```bash
# Directly from GitHub
mcp tools npx -y github:someuser/their-mcp-server

# Or clone first
git clone https://github.com/user/cool-mcp-server
cd cool-mcp-server && npm install && npm run build
mcp tools node ./dist/index.js
```

### Use an HTTP MCP endpoint
```bash
# Connect to remote MCP server
mcp tools https://mcp-api.example.com/mcp
mcp call some_tool -p '{"data": "here"}' https://mcp-api.example.com/mcp
```

## Notes

- Use `-y` with npx to auto-confirm package installation
- First run of npm packages may be slow (downloading)
- Use `-f json` when parsing output programmatically
- Check server docs for required environment variables
- Any MCP-compliant server works - npm, pip, binary, or HTTP
