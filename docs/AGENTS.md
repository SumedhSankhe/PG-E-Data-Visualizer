# Repository Sub-Agents

This document defines specialized sub-agents (automation personas or contributor guidelines) for the PG&E Data Visualizer Shiny app. Each agent has a scope, responsibilities, inputs, outputs, and checklists.

## 1. Shiny Development Agent
- Focus: Server logic, reactive architecture, module patterns, performance.
- Inputs: Proposed feature spec, existing module code (`loadData`, `analyse`, `home`), global constants in `global.R`.
- Outputs: New/modified module code, unit test script(s), performance notes.
- Checklist:
  - Use Shiny Module pattern (`modNameUI`, `modNameServer`).
  - Avoid long-running ops in reactive contexts; prefer `future` or pre-compute where needed.
  - Use `req()` and `validate(need())` for user feedback.
  - Ensure reactive isolation with `isolate()` when side-effects are unwanted.
  - Profile with `reactlog::reactlog_enable()` (dev only) and document bottlenecks.

## 2. UI/UX Agent
- Focus: Layout, accessibility, consistency, responsiveness.
- Inputs: `ui.R`, component proposals, CSS snippets.
- Outputs: Updated UI code, CSS additions, style guidance.
- Checklist:
  - Maintain dashboard structure; group controls logically.
  - Ensure labels and placeholders are descriptive.
  - Provide accessible color contrast (WCAG AA where feasible).
  - Use `title`, `aria-label` where relevant for custom HTML.
  - Keep horizontal scrolling minimal; prefer wrapping.
  - Document any new CSS in `docs/STYLE.md`.

## 3. Documentation Agent
- Focus: README, inline comments, function docs, user guides.
- Inputs: New features, existing undocumented functions.
- Outputs: Updated `README.md`, `docs/CHANGELOG.md`, roxygen-style comments.
- Checklist:
  - Each exported function or module gets roxygen block.
  - Update README feature list & quick start if behavior changes.
  - Append version section in CHANGELOG (Keep a `## [Unreleased]` section).
  - Provide minimal reproducible example for complex modules.

## 4. Code Review Agent
- Focus: Code quality, modularity, consistency, test coverage.
- Inputs: Pull request diff, lint report, test results.
- Outputs: Review comments, approval status, follow-up tasks.
- Checklist:
  - Confirm adherence to module naming and file structure.
  - Ensure no wide-scope variables leaked (use namespaced `NS()`).
  - Check for orphaned reactives or observers.
  - Demand at least one test (if test infra present) for new reactive logic.
  - Verify error handling messages are user-friendly.

## 5. Linting & Style Agent
- Focus: Static analysis, formatting, dependency hygiene.
- Inputs: Source files, `.lintr` config, style rules.
- Outputs: Lint report, applied formatting, dependency suggestions.
- Checklist:
  - Run `lintr::lint_package()`.
  - Run `styler::style_dir()` (exclude `renv/`).
  - Flag unused library calls in `global.R` / `ui.R`.
  - Ensure consistent tidyverse style (snake_case, spaces around `=` in named args).
  - Record lint summary in PR comments.

## Interaction Flow
1. Author opens PR with feature or fix.
2. Linting Agent runs style + lint; attaches report.
3. Shiny Dev Agent reviews reactive correctness & performance.
4. UI/UX Agent refines layout & accessibility.
5. Documentation Agent updates docs & CHANGELOG.
6. Code Review Agent performs final holistic review.
7. Merge if all checklists satisfied.

## Automation Hooks (Suggested)
- Pre-commit: Run `scripts/style.R`; block on errors.
- CI Step 1: `scripts/lint.R` generate artifact.
- CI Step 2: Shiny test script (future enhancement) using `shinytest2`.

## Future Enhancements
- Add `shinytest2` snapshot tests.
- Add performance metrics (render time) instrumentation.
- Introduce accessibility scanning (pa11y via headless browser).

---
Keep this doc updated as processes evolve.
