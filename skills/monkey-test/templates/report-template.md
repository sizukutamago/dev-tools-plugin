# Monkey Test Report

> Target: {target_url}
> Date: {YYYY-MM-DD}
> Context Mode: {url-only | url+spec | url+codebase}
> Agents: {N}
> Total Actions: {used}/{budget}
> Total Issues: {count}

## Executive Summary

| Severity | Count |
|----------|-------|
| Critical | - |
| High | - |
| Medium | - |
| Low | - |

**Top findings**:
1. **[{Severity}]** {Summary} ({agent-name})
2. **[{Severity}]** {Summary} ({agent-name})
3. **[{Severity}]** {Summary} ({agent-name})

---

## Critical & High Issues

### ISSUE-{NNN}: {Issue Title} [{Severity}]

**Found by**: {agent-name} (SEQ-{NNN}, Step {N})
**Page**: {URL}
**Description**: {詳細説明}
**Screenshot**: ![{alt}](screenshots/{filename}.png)
**Reproduction Steps**:
1. {Step 1}
2. {Step 2}
3. {Step 3}

**Recommendation**: {修正提案}

---

## All Issues by Agent

### {agent-display-name} ({N} issues)

| ID | Severity | Summary | Page |
|----|----------|---------|------|
| ISS-{XX}-{NNN} | {severity} | {summary} | {page} |

---

## Coverage Summary

| Agent | Pages | Elements | Forms | Actions Used |
|-------|-------|----------|-------|-------------|
| {agent} | {n}/{total} | {n}/{total} | {n}/{total} | {used}/{budget} |
| **Combined** | **{n}/{total}** | **{n}/{total} ({pct}%)** | **{n}/{total}** | **{total_used}/{total_budget}** |

---

## Console Errors

| Page | Error Message | Agent | Sequence |
|------|--------------|-------|----------|
| {url} | {message} | {agent} | SEQ-{NNN} |

## Network Errors

| URL | Status | Method | Agent | Sequence |
|-----|--------|--------|-------|----------|
| {url} | {status} | {method} | {agent} | SEQ-{NNN} |

---

## Stability Metrics

| Agent | Self-Heal Attempts | Self-Heal Success | Self-Heal Rate | Wait Extensions | Flake Rate |
|-------|-------------------|-------------------|----------------|-----------------|------------|
| {agent} | {attempts} | {successes} | {rate}% | {wait_count} | {flake_pct}% |
| **Total** | **{total}** | **{total}** | **{rate}%** | **{total}** | **{rate}%** |

### Self-Healing Details

| Agent | Original Ref | New Ref | Page | Element Type |
|-------|-------------|---------|------|-------------|
| {agent} | {E-NNN} | {ref} | {url} | {type} |

---

## Appendix: Agent Configurations

| Agent | Personality | Model | Action Budget |
|-------|-------------|-------|---------------|
| {agent} | {personality} | {model} | {budget} |

## Appendix: Test Environment

| Item | Value |
|------|-------|
| Target URL | {url} |
| Context Mode | {mode} |
| Auth Required | {yes/no} |
| Recon Pages | {N} |
| Recon Elements | {N} |
| Recon Hash | {hash} |
