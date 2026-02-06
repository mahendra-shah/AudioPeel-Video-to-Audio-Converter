---
description: "Repository-level behavior and file creation rules."
applyTo: "**/*"
---

# Repository Behavior Rules

You are working inside a production Flutter application.

## File Creation Policy

- DO NOT create Markdown (.md) files in the project root.
- DO NOT create Markdown files inside lib/, test/, or any feature folders.
- If documentation is required, ALWAYS create it inside:

  /docs

- If /docs does not exist, create it and place documentation there.
- Never create planning, reasoning, scratch, summary, or temporary Markdown files.

## Scope Control

- Only modify files directly related to the task.
- Do not introduce new files unless strictly necessary.
- If a new file is required, explain in chat why it is needed before creating it.

## Clean Repository Policy

- No temporary artifacts.
- No implementation summaries saved as files.
- No agent logs.
- All explanations remain in chat unless explicitly asked to persist.

## Flutter Project Context

This is a layered Flutter architecture project.

Follow:
- Data layer
- Domain layer (if used)
- UI layer (MVVM)
- Repository pattern
- Immutable models

Do not break architectural boundaries.
