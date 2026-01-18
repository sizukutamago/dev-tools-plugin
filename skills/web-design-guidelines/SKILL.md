---
name: web-design-guidelines
description: This skill should be used when the user asks to "review my UI", "check accessibility", "audit design", "review UX", "check best practices", or "validate web interface". Reviews UI code for Web Interface Guidelines compliance.
version: 1.0.0
---

# Web Interface Guidelines

Review files for compliance with Web Interface Guidelines.

## How It Works

1. Read the local guidelines reference file first
2. Optionally fetch the latest guidelines from the source URL (for updates)
3. Read the specified files (or prompt user for files/pattern)
4. Check against all rules in the guidelines
5. Output findings in the terse `file:line` format

## Guidelines Source

### Local Reference (Primary)

```
{baseDir}/references/guidelines.md
```

This file contains a cached version of the Web Interface Guidelines for offline use.

### Online Source (Optional - for latest updates)

```
https://raw.githubusercontent.com/vercel-labs/web-interface-guidelines/main/command.md
```

Use WebFetch to retrieve the latest rules if online access is available.

## Usage

When a user provides a file or pattern argument:
1. Read local guidelines from `{baseDir}/references/guidelines.md`
2. (Optional) Fetch latest guidelines from online source for updates
3. Read the specified files
4. Apply all rules from the guidelines
5. Output findings using the format specified in the guidelines

If no files specified, ask the user which files to review.

## Offline Support

This skill works offline using the local reference file. For the latest guidelines, internet access is recommended but not required.
