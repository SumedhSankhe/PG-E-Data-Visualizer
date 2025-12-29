# Code Review Checklist

Use this checklist during reviews and automated agent passes.

## General
- [ ] PR title is descriptive
- [ ] Linked issue / context provided
- [ ] Scope is limited (no unrelated refactors)

## Shiny Modules
- [ ] UI and Server components follow `nameUI` / `nameServer`
- [ ] `NS(id)` used for all input/output ids
- [ ] Reactive expressions have clear naming (`data_filtered`, `plot_data`)
- [ ] `observeEvent` used instead of `observe` when reacting to specific triggers
- [ ] `req()` safeguards prior to data-dependent operations

## Performance
- [ ] No heavy computation inside `render*` without caching
- [ ] Long operations offloaded or documented
- [ ] No redundant `fread` / disk I/O in reactives

## UI/UX & Accessibility
- [ ] Labels are meaningful
- [ ] Color contrast acceptable (manual spot check)
- [ ] No excessive horizontal scroll without justification
- [ ] Tab order logical

## Code Quality
- [ ] No commented-out large blocks left behind (unless TODO)
- [ ] No unused libraries loaded
- [ ] Consistent style (snake_case, spacing)
- [ ] Functions < ~60 lines or logically split

## Error Handling
- [ ] `validate(need())` messages are user-friendly
- [ ] Failing states handled gracefully (empty data, missing columns)

## Documentation
- [ ] README updated if user-facing change
- [ ] Roxygen comments for new exported functions/modules
- [ ] CHANGELOG updated

## Testing (if available)
- [ ] At least one test added for new logic
- [ ] Existing tests pass locally/CI

## Security / Data Hygiene
- [ ] No hard-coded secrets or paths
- [ ] Inputs sanitized if used in file paths / queries

## Linting
- [ ] Lint report attached
- [ ] Critical issues addressed

## Merge Readiness
- [ ] All agents approved
- [ ] CI green
- [ ] No unresolved review comments
