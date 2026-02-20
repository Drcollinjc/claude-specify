# claude-specify — Design Evolution

This directory captures the design thinking, decisions, and learnings that shaped the claude-specify plugin. Documents are numbered chronologically to show the evolution from concept to current state.

## Timeline

### 01 — Design Thesis (Feb 2026)

The foundational reasoning for why spec-driven development exists. Captures the "organisational infrastructure" reframing — this is not a personal workflow, it's governance infrastructure for AI-assisted engineering at scale. Covers the contested decisions (watermark system, constitution, validator gates) with both positions recorded.

### 02 — Release 006: Spec-Driven Refactor (Feb 2026)

Release notes for the major refactor that transformed the system from project-embedded commands into a standalone plugin. Three waves: structural refactor (commands, templates, scripts, rules), flow fixes from Level 1-2 testing, and the constitution redesign (v4 to v5 — two-document governance model with product thesis + engineering constitution).

### 03 — Token Usage Forensic Analysis (Feb 2026)

Comprehensive cost analysis of the 008 pipeline run (~$87.84 on Opus). Breaks down token usage by pipeline stage, identifies the top cost drivers (stale context replay, wrong model for task type, unnecessary full-file reads), and projects an optimised cost of ~$54.20 (38% reduction). This analysis directly drove the optimisation workstreams.

### 04 — Harness Evolution Design Document (Feb 2026)

The most comprehensive document. Synthesises research from OpenAI harness engineering, StrongDM Factory techniques, git worktrees, and LLM eval frameworks into a three-pillar architecture (context efficiency, mechanical enforcement, intelligence validation). Contains 17 architectural decisions, 7 workstreams, a red team analysis, and execution status tracking. This is the current active design document.

## Reading Order

- **New to the project?** Start with 01 (the why) then 04 (the current state).
- **Understanding costs?** Read 03 then the optimisation sections of 04.
- **Understanding the refactor?** Read 02 for the structural changes.
