# Repository Sub-Agents - Complete Lifecycle Management

This document defines specialized sub-agents (automation personas or contributor guidelines) for the PG&E Data Visualizer Shiny app. Each agent has a scope, responsibilities, inputs, outputs, and checklists covering the complete development lifecycle.

---

## PHASE 1: PLANNING & DESIGN

### 1. Product Planning Agent
**Focus:** Feature ideation, requirements gathering, roadmap planning, user stories.

**Inputs:**
- User feedback, feature requests
- Business requirements documents
- Competitive analysis
- Analytics data on usage patterns

**Outputs:**
- Feature specifications
- User stories with acceptance criteria
- Roadmap prioritization
- Technical feasibility assessments

**Checklist:**
- [ ] User story follows format: "As a [user], I want [goal] so that [benefit]"
- [ ] Acceptance criteria are measurable and testable
- [ ] Dependencies and blockers identified
- [ ] Estimated effort and complexity documented
- [ ] Stakeholder alignment confirmed
- [ ] Security and privacy implications considered

**Example User Stories:**
- As an energy analyst, I want to compare multiple rate plans side-by-side so that I can recommend the most cost-effective option
- As a homeowner, I want to see my peak usage hours highlighted so that I can shift consumption to save money

---

### 2. Data Architecture Agent
**Focus:** Data models, schema design, data flow, storage strategies, data validation.

**Inputs:**
- Sample PG&E meter data files
- Data format specifications
- Performance requirements
- Storage constraints

**Outputs:**
- Data model documentation
- Column specifications and types
- Data validation rules
- ETL pipeline designs
- Sample data generators

**Checklist:**
- [ ] Required vs. optional columns clearly defined
- [ ] Data types and formats documented (datetime formats, numeric precision)
- [ ] Validation rules implemented (range checks, null handling)
- [ ] Missing data strategies defined
- [ ] Data transformations documented
- [ ] Performance implications of data size considered
- [ ] Privacy/PII concerns addressed
- [ ] Backup and archival strategies defined

**Key Data Specifications:**
```r
# Core Schema
REQUIRED_COLUMNS <- c("dttm_start", "hour", "value", "day", "day2")
OPTIONAL_COLUMNS <- c("day_of_week", "month", "year", "season")

# Validation Rules
- dttm_start: POSIXct, no future dates
- hour: 0-23 integer
- value: non-negative numeric (kWh)
- day/day2: positive integer identifiers
```

---

### 3. UI/UX Design Agent
**Focus:** User experience, interface design, accessibility, visual consistency, user flows.

**Inputs:**
- User personas and use cases
- Wireframes and mockups
- Accessibility guidelines (WCAG 2.1)
- Brand guidelines
- Existing UI components in `ui.R`

**Outputs:**
- Updated UI code with improved layouts
- CSS/styling enhancements
- Accessibility improvements
- User flow diagrams
- Design system documentation

**Checklist:**
- [ ] Dashboard layout is intuitive and logically organized
- [ ] Controls are grouped by functionality
- [ ] Labels and placeholders are descriptive
- [ ] Color contrast meets WCAG AA standards (4.5:1 for text)
- [ ] Interactive elements have clear hover/focus states
- [ ] Error messages are user-friendly and actionable
- [ ] Loading states provide feedback for async operations
- [ ] Responsive design tested on different screen sizes
- [ ] Keyboard navigation works properly (tab order)
- [ ] ARIA labels used for custom components
- [ ] Tooltips provide contextual help
- [ ] Consistent spacing and alignment (use grid system)

**Color Palette:**
```
Primary: #3498db (blue)
Success: #28a745 (green)
Warning: #ffc107 (yellow)
Danger: #dc3545 (red)
Info: #17a2b8 (cyan)
Dark: #2c3e50
Light: #ecf0f1
```

---

## PHASE 2: DEVELOPMENT

### 4. Shiny Development Agent
**Focus:** Server logic, reactive architecture, module patterns, performance optimization.

**Inputs:**
- Feature specifications
- Existing module code (`loadData.R`, `analyse.R`, `home.R`)
- Global constants in `global.R`
- Performance requirements

**Outputs:**
- New/modified module code
- Reactive graph documentation
- Unit test scripts
- Performance profiling reports

**Checklist:**
- [ ] Use Shiny Module pattern (`modNameUI`, `modNameServer`)
- [ ] All input/output IDs use `NS(id)` namespacing
- [ ] Reactive expressions have clear, descriptive names
- [ ] Use `req()` to guard against NULL/missing inputs
- [ ] Use `validate(need())` for user-friendly error messages
- [ ] Use `observeEvent()` instead of `observe()` for specific triggers
- [ ] Avoid long-running operations in reactive contexts
- [ ] Consider `bindCache()` for expensive computations
- [ ] Use `isolate()` to prevent unwanted reactive dependencies
- [ ] Profile with `reactlog::reactlog_enable()` in development
- [ ] Document reactive dependencies and data flow
- [ ] Handle edge cases (empty data, single row, missing columns)
- [ ] Log important state changes using `logger`

**Module Template:**
```r
# UI Function
moduleNameUI <- function(id, label = "module_name") {
  ns <- NS(id)
  tagList(
    # UI elements here
  )
}

# Server Function
moduleNameServer <- function(id, shared_data) {
  moduleServer(
    id,
    function(input, output, session) {
      # Reactive logic here
      # Use req(), validate(), logger
    }
  )
}
```

---

### 5. Data Visualization Agent
**Focus:** Charts, plots, interactive visualizations, visual analytics.

**Inputs:**
- Data specifications
- Visualization requirements
- User interaction needs
- Accessibility standards

**Outputs:**
- ggplot2 and plotly chart code
- Interactive plot configurations
- Visual design documentation
- Color scheme selections

**Checklist:**
- [ ] Chart type appropriate for data and question
- [ ] Axes labeled clearly with units
- [ ] Legends positioned appropriately
- [ ] Color palette is colorblind-friendly
- [ ] Interactive features enhance understanding (hover, zoom, pan)
- [ ] Loading spinners for plots that take >1 second
- [ ] Error states handled gracefully (empty data, invalid filters)
- [ ] Plot dimensions responsive to container size
- [ ] Annotations and reference lines used where helpful
- [ ] Export options available (PNG, SVG, PDF)
- [ ] Performance tested with large datasets
- [ ] Consistent styling across all visualizations

**Visualization Types:**
- Time series: Line plots with trend lines
- Distribution: Box plots, histograms, density plots
- Comparison: Bar charts, grouped bar charts
- Correlation: Scatter plots with regression lines
- Composition: Stacked area charts, pie charts (use sparingly)

---

### 6. Backend Logic Agent
**Focus:** Business logic, calculations, data processing, algorithms.

**Inputs:**
- Rate plan specifications
- Pricing formulas
- Data transformation requirements
- Performance constraints

**Outputs:**
- Calculation functions
- Data processing pipelines
- Algorithm implementations
- Unit tests for logic

**Checklist:**
- [ ] Functions are pure when possible (no side effects)
- [ ] Input validation at function boundaries
- [ ] Vectorized operations used for performance
- [ ] Edge cases handled (division by zero, empty vectors)
- [ ] Constants extracted to `global.R`
- [ ] Complex calculations documented with formulas
- [ ] Unit tests cover normal and edge cases
- [ ] Performance profiled with `microbenchmark` or `profvis`
- [ ] Functions kept under 60 lines or logically split
- [ ] Return values clearly documented

**Rate Plan Calculation Example:**
```r
#' Calculate electricity cost for Time of Use plan
#' @param consumption_kwh Numeric vector of consumption in kWh
#' @param hour_of_day Integer vector (0-23)
#' @param peak_start Peak period start hour (default 16)
#' @param peak_end Peak period end hour (default 21)
#' @param peak_rate Rate during peak hours ($/kWh)
#' @param offpeak_rate Rate during off-peak hours ($/kWh)
#' @return Numeric vector of costs in dollars
calculate_tou_cost <- function(consumption_kwh, hour_of_day,
                                peak_start = 16, peak_end = 21,
                                peak_rate = 0.45, offpeak_rate = 0.25) {
  # Validation
  stopifnot(length(consumption_kwh) == length(hour_of_day))
  stopifnot(all(hour_of_day >= 0 & hour_of_day <= 23))

  # Vectorized calculation
  is_peak <- hour_of_day >= peak_start & hour_of_day <= peak_end
  cost <- ifelse(is_peak,
                 consumption_kwh * peak_rate,
                 consumption_kwh * offpeak_rate)
  return(cost)
}
```

---

## PHASE 3: QUALITY ASSURANCE

### 7. Testing Agent
**Focus:** Unit tests, integration tests, UI tests, test coverage.

**Inputs:**
- Module code
- Test requirements
- Edge cases and scenarios
- Existing test suite in `tests/testthat/`

**Outputs:**
- Test scripts using `testthat`
- UI snapshot tests using `shinytest2`
- Test coverage reports
- Regression test suites

**Checklist:**
- [ ] Each module has corresponding test file
- [ ] Unit tests cover core business logic
- [ ] Edge cases tested (NULL, empty, extreme values)
- [ ] Test names are descriptive: `test_that("description", {...})`
- [ ] Use `testServer()` for testing reactive logic
- [ ] Mock external dependencies (file I/O, APIs)
- [ ] Tests run independently (no shared state)
- [ ] Coverage target: >80% for critical paths
- [ ] Performance regression tests for key operations
- [ ] UI snapshot tests for major workflows
- [ ] Tests documented with setup and teardown steps

**Test Structure:**
```r
# tests/testthat/test_module_name.R
library(testthat)
library(shiny)

test_that("module handles empty data gracefully", {
  testServer(moduleNameServer, {
    session$setInputs(data = data.frame())
    expect_true(is.null(output$plot))
    expect_match(output$message, "No data available")
  })
})

test_that("calculate_tou_cost returns correct values", {
  consumption <- c(10, 15, 20)
  hours <- c(12, 18, 22)  # off-peak, peak, off-peak
  result <- calculate_tou_cost(consumption, hours,
                                peak_rate = 0.40, offpeak_rate = 0.20)
  expected <- c(2.0, 6.0, 4.0)
  expect_equal(result, expected)
})
```

---

### 8. Code Review Agent
**Focus:** Code quality, best practices, security, maintainability.

**Inputs:**
- Pull request diffs
- Lint reports
- Test results
- CODE_REVIEW_CHECKLIST.md

**Outputs:**
- Review comments
- Approval or change requests
- Identified issues and suggestions
- Follow-up tasks

**Checklist:**
- [ ] Code follows module naming conventions
- [ ] No leaked variables (proper use of `NS()`)
- [ ] No orphaned reactives or observers
- [ ] Error handling is comprehensive and user-friendly
- [ ] No hard-coded secrets or file paths
- [ ] Inputs sanitized before use in file paths or queries
- [ ] No commented-out code blocks (unless marked TODO)
- [ ] Functions are reasonably sized (<60 lines)
- [ ] Complex logic has explanatory comments
- [ ] Security vulnerabilities checked (XSS, injection)
- [ ] Performance implications considered
- [ ] Backwards compatibility maintained
- [ ] Migration path provided for breaking changes

**Security Checklist:**
- [ ] No SQL injection vulnerabilities
- [ ] File upload restrictions enforced (type, size)
- [ ] User inputs validated and sanitized
- [ ] No eval() or similar dynamic code execution
- [ ] Sensitive data not logged
- [ ] Dependencies regularly updated (renv)

---

### 9. Linting & Style Agent
**Focus:** Code formatting, style consistency, static analysis.

**Inputs:**
- Source files (`.R`)
- `.lintr` configuration
- Style guide (tidyverse)

**Outputs:**
- Lint reports
- Auto-formatted code
- Style violation summaries
- Dependency analysis

**Checklist:**
- [ ] Run `lintr::lint_package()` and address critical issues
- [ ] Run `styler::style_dir(exclude_dirs = "renv")`
- [ ] Variable names use snake_case
- [ ] Function names use snake_case
- [ ] Constants use UPPER_SNAKE_CASE
- [ ] Consistent indentation (2 spaces)
- [ ] Line length ≤ 120 characters
- [ ] Spaces around operators (`=`, `<-`, `+`, etc.)
- [ ] No trailing whitespace
- [ ] File ends with newline
- [ ] No unused library() calls
- [ ] Imports organized and documented
- [ ] Attach lint report to PR

**Configuration:**
```r
# .lintr
linters: linters_with_defaults(
  line_length_linter(120),
  object_length_linter(40),
  cyclocomp_linter(15),
  commented_code_linter = NULL
)
exclude: "renv"
```

---

### 10. Performance Testing Agent
**Focus:** Load testing, profiling, optimization, scalability.

**Inputs:**
- Application code
- Sample datasets of varying sizes
- Performance benchmarks
- User concurrency scenarios

**Outputs:**
- Profiling reports (`profvis`)
- Benchmark results
- Performance recommendations
- Optimization patches

**Checklist:**
- [ ] Profile with `profvis::profvis()` for bottlenecks
- [ ] Test with realistic data sizes (100 rows, 10K rows, 100K rows)
- [ ] Measure render times for all plots
- [ ] Test concurrent user loads (use `shinyloadtest`)
- [ ] Identify memory leaks or unbounded growth
- [ ] Cache expensive computations with `bindCache()`
- [ ] Use `data.table` for large data operations
- [ ] Minimize reactive invalidations
- [ ] Pre-compute static elements
- [ ] Document performance characteristics
- [ ] Set performance budgets (e.g., plots render <2s)

**Profiling Workflow:**
```r
# Wrap expensive operations
profvis::profvis({
  # Code to profile
  result <- analyseServer("test", data)
})

# Benchmark functions
microbenchmark::microbenchmark(
  calculate_tou_cost(data$consumption, data$hour),
  times = 100
)
```

---

### 11. Accessibility Testing Agent
**Focus:** WCAG compliance, keyboard navigation, screen reader support.

**Inputs:**
- UI code
- WCAG 2.1 guidelines
- Accessibility audit tools

**Outputs:**
- Accessibility audit reports
- ARIA label improvements
- Keyboard navigation fixes
- Color contrast adjustments

**Checklist:**
- [ ] All interactive elements keyboard accessible
- [ ] Tab order is logical
- [ ] Focus indicators visible
- [ ] ARIA labels on custom controls
- [ ] Alt text for images and icons
- [ ] Color not sole means of conveying information
- [ ] Text contrast ratio ≥ 4.5:1 (AA) or 7:1 (AAA)
- [ ] Form inputs have associated labels
- [ ] Error messages announced to screen readers
- [ ] Skip navigation links provided
- [ ] Test with screen reader (NVDA, JAWS, VoiceOver)
- [ ] Responsive design works at 200% zoom

**Tools:**
- `pa11y` for automated scanning
- Browser DevTools accessibility audits
- `axe` extension for detailed analysis

---

## PHASE 4: DEPLOYMENT & OPERATIONS

### 12. DevOps & CI/CD Agent
**Focus:** Continuous integration, deployment pipelines, infrastructure, automation.

**Inputs:**
- Application code
- CI/CD configuration (`.github/workflows/`)
- Deployment environments (dev, staging, prod)
- Infrastructure requirements

**Outputs:**
- Updated CI/CD pipelines
- Deployment scripts
- Infrastructure as code
- Environment configurations

**Checklist:**
- [ ] CI pipeline runs on PR to main/master
- [ ] Automated linting step with artifact upload
- [ ] Automated test execution with coverage reporting
- [ ] Build artifacts created and versioned
- [ ] Environment variables managed securely
- [ ] Deployment process documented
- [ ] Rollback procedure defined
- [ ] Health checks configured
- [ ] Monitoring and alerting set up
- [ ] Secrets managed via environment variables (not committed)
- [ ] Dependencies installed via `renv::restore()`
- [ ] Log aggregation configured

**CI Pipeline Stages:**
```yaml
1. Install dependencies (renv)
2. Run linter (lintr)
3. Run style check (styler)
4. Run unit tests (testthat)
5. Generate coverage report (covr)
6. Build application
7. Deploy to staging (if main branch)
8. Run smoke tests
9. Deploy to production (if tagged release)
```

---

### 13. Monitoring & Observability Agent
**Focus:** Logging, metrics, error tracking, user analytics.

**Inputs:**
- Application logs (`logs/app-*.log`)
- Performance metrics
- Error reports
- User behavior data

**Outputs:**
- Log analysis reports
- Performance dashboards
- Alert configurations
- Incident reports

**Checklist:**
- [ ] Structured logging implemented (using `logger`)
- [ ] Log levels used appropriately (DEBUG, INFO, WARN, ERROR)
- [ ] Sensitive data not logged
- [ ] Log rotation configured (daily rotation in place)
- [ ] Error tracking integrated (e.g., Sentry)
- [ ] Performance metrics collected (response times, memory usage)
- [ ] User analytics tracked (page views, feature usage)
- [ ] Alerting configured for critical errors
- [ ] Dashboards created for key metrics
- [ ] Log retention policy defined
- [ ] Privacy compliance for user data

**Logging Best Practices:**
```r
# Use appropriate log levels
logger::log_info("User uploaded file: {filename}")
logger::log_warn("Missing column 'hour' in uploaded data")
logger::log_error("Failed to process data: {error_message}")

# Log important events
logger::log_info("Rate plan selected: {input$plan_type}")
logger::log_info("Date range changed: {input$date_range[1]} to {input$date_range[2]}")

# Log performance
start_time <- Sys.time()
result <- expensive_operation()
elapsed <- difftime(Sys.time(), start_time, units = "secs")
logger::log_info("Operation completed in {elapsed} seconds")
```

---

## PHASE 5: MAINTENANCE & EVOLUTION

### 14. Documentation Maintenance Agent
**Focus:** README, changelogs, API docs, user guides, inline comments.

**Inputs:**
- New features and changes
- User feedback and FAQs
- Existing documentation
- Code comments

**Outputs:**
- Updated README.md
- CHANGELOG.md entries
- Roxygen documentation
- User guides and tutorials
- API documentation

**Checklist:**
- [ ] README.md reflects current features and setup
- [ ] CHANGELOG.md updated with version and changes
- [ ] All exported functions have roxygen comments
- [ ] Complex logic has explanatory comments
- [ ] User guide updated for new features
- [ ] Code examples provided for common use cases
- [ ] Breaking changes clearly documented
- [ ] Migration guides for major version updates
- [ ] Screenshots updated if UI changed
- [ ] FAQ section maintained

**Documentation Structure:**
```
docs/
├── README.md              # Project overview and quick start
├── CHANGELOG.md           # Version history
├── AGENTS.md             # This file
├── CODE_REVIEW_CHECKLIST.md
├── STYLE.md              # CSS and design guidelines
├── USER_GUIDE.md         # Detailed user manual
├── API.md                # Function reference
├── DEPLOYMENT.md         # Deployment instructions
└── CONTRIBUTING.md       # Contributor guidelines
```

---

### 15. Dependency Management Agent
**Focus:** Package updates, security patches, dependency conflicts, renv management.

**Inputs:**
- `renv.lock` file
- Security advisories
- Package update notifications
- Compatibility requirements

**Outputs:**
- Updated dependencies
- Security patch reports
- Compatibility testing results
- renv snapshots

**Checklist:**
- [ ] Dependencies regularly reviewed (monthly)
- [ ] Security vulnerabilities addressed promptly
- [ ] Breaking changes in dependencies tested
- [ ] `renv.lock` committed after updates
- [ ] Dependency conflicts resolved
- [ ] Unused dependencies removed
- [ ] Minimum R version specified
- [ ] Platform-specific dependencies documented
- [ ] Update strategy defined (conservative vs. aggressive)
- [ ] Rollback plan for problematic updates

**Update Workflow:**
```r
# Check for outdated packages
renv::status()

# Update specific package
renv::update("shiny")

# Update all packages
renv::update()

# Snapshot current state
renv::snapshot()

# Restore from snapshot if issues
renv::restore()
```

---

### 16. Bug Triage & Fix Agent
**Focus:** Issue management, bug reproduction, root cause analysis, fixes.

**Inputs:**
- GitHub issues
- User bug reports
- Error logs
- Stack traces

**Outputs:**
- Issue labels and priorities
- Reproduction steps
- Root cause analysis
- Bug fixes and patches
- Regression tests

**Checklist:**
- [ ] Issue reproduced and documented
- [ ] Steps to reproduce clearly listed
- [ ] Expected vs. actual behavior described
- [ ] Environment details captured (R version, OS, browser)
- [ ] Root cause identified
- [ ] Fix implemented with tests
- [ ] Regression test added to prevent recurrence
- [ ] Related issues linked
- [ ] Fix documented in CHANGELOG
- [ ] User notified when resolved

**Issue Template:**
```markdown
## Bug Report

**Description:**
Brief description of the bug

**Steps to Reproduce:**
1. Go to Data tab
2. Upload file with missing 'hour' column
3. Navigate to Analyse tab
4. Observe error

**Expected Behavior:**
Friendly error message about missing column

**Actual Behavior:**
Application crashes with stack trace

**Environment:**
- R version: 4.3.0
- Shiny version: 1.7.5
- Browser: Chrome 120
- OS: Windows 11

**Screenshots/Logs:**
[Attach relevant logs or screenshots]
```

---

### 17. Feature Request Evaluation Agent
**Focus:** Feature assessment, feasibility analysis, prioritization.

**Inputs:**
- Feature requests from users
- Product roadmap
- Technical constraints
- Resource availability

**Outputs:**
- Feature specifications
- Feasibility assessments
- Effort estimates
- Prioritized backlog

**Checklist:**
- [ ] User need clearly articulated
- [ ] Use case and user story defined
- [ ] Alignment with product vision confirmed
- [ ] Technical feasibility assessed
- [ ] Dependencies and blockers identified
- [ ] Effort estimated (story points or hours)
- [ ] Priority assigned (critical, high, medium, low)
- [ ] Alternatives considered
- [ ] Security and privacy implications reviewed
- [ ] Resource requirements identified
- [ ] Success metrics defined

**Evaluation Criteria:**
- **Impact:** How many users benefit?
- **Effort:** How complex is implementation?
- **Alignment:** Does it fit product vision?
- **Urgency:** How time-sensitive is it?
- **Risk:** What are the technical risks?

---

### 18. User Support Agent
**Focus:** User assistance, troubleshooting, documentation gaps, feedback collection.

**Inputs:**
- User questions and issues
- Application logs
- Documentation
- Support tickets

**Outputs:**
- Support responses
- Troubleshooting guides
- FAQ updates
- Documentation improvements
- Feature requests from user feedback

**Checklist:**
- [ ] User issue understood and clarified
- [ ] Relevant logs reviewed
- [ ] Reproduction attempted
- [ ] Solution provided or escalated
- [ ] Response time within SLA
- [ ] Documentation updated if gap identified
- [ ] FAQ updated for common issues
- [ ] Feature requests captured and forwarded
- [ ] User satisfaction confirmed
- [ ] Patterns in support requests analyzed

**Common Support Topics:**
- Data upload issues (format, missing columns)
- Visualization not rendering
- Rate plan configuration
- Performance issues with large files
- Interpretation of results

---

## PHASE 6: CROSS-CUTTING CONCERNS

### 19. Security Agent
**Focus:** Security vulnerabilities, threat modeling, secure coding practices.

**Inputs:**
- Application code
- Security best practices
- Vulnerability reports
- Threat models

**Outputs:**
- Security audit reports
- Vulnerability patches
- Security documentation
- Threat mitigation strategies

**Checklist:**
- [ ] Input validation on all user inputs
- [ ] File upload restrictions (type, size, content validation)
- [ ] No SQL injection vulnerabilities
- [ ] No XSS vulnerabilities in rendered HTML
- [ ] No code injection (avoid eval, parse)
- [ ] Sensitive data encrypted at rest and in transit
- [ ] Authentication and authorization implemented
- [ ] Session management secure
- [ ] CSRF protection enabled
- [ ] Security headers configured
- [ ] Dependencies scanned for vulnerabilities
- [ ] Secrets not committed to version control
- [ ] Logs don't contain sensitive data
- [ ] Error messages don't leak system info

**OWASP Top 10 Considerations:**
1. Injection (SQL, command, code)
2. Broken authentication
3. Sensitive data exposure
4. XML external entities (XXE)
5. Broken access control
6. Security misconfiguration
7. Cross-site scripting (XSS)
8. Insecure deserialization
9. Using components with known vulnerabilities
10. Insufficient logging and monitoring

---

### 20. Data Privacy & Compliance Agent
**Focus:** GDPR, CCPA, data handling policies, privacy compliance.

**Inputs:**
- Data processing activities
- Privacy regulations (GDPR, CCPA)
- Data retention policies
- User consent mechanisms

**Outputs:**
- Privacy impact assessments
- Data processing documentation
- Compliance reports
- Privacy policy updates

**Checklist:**
- [ ] Data collection justified and documented
- [ ] User consent obtained where required
- [ ] Privacy policy clear and accessible
- [ ] Data minimization principle applied
- [ ] Data retention periods defined
- [ ] User rights implemented (access, deletion, portability)
- [ ] Data breach response plan in place
- [ ] Third-party data processors vetted
- [ ] Cross-border data transfers compliant
- [ ] Privacy by design principles followed
- [ ] Regular privacy audits conducted

**PII Handling:**
- Avoid collecting PII unless necessary
- Encrypt PII at rest and in transit
- Anonymize or pseudonymize where possible
- Provide user data export functionality
- Implement data deletion workflows

---

## INTERACTION FLOWS

### Flow 1: New Feature Development
```
1. Product Planning Agent → defines feature spec
2. Data Architecture Agent → designs data model changes
3. UI/UX Design Agent → creates interface designs
4. Shiny Development Agent → implements backend logic
5. Data Visualization Agent → creates visualizations
6. Testing Agent → writes and runs tests
7. Linting & Style Agent → enforces code quality
8. Code Review Agent → reviews implementation
9. Documentation Agent → updates docs
10. DevOps Agent → deploys to staging
11. Performance Testing Agent → validates performance
12. Accessibility Agent → validates accessibility
13. DevOps Agent → deploys to production
14. Monitoring Agent → tracks metrics
```

### Flow 2: Bug Fix Workflow
```
1. User Support Agent → receives bug report
2. Bug Triage Agent → reproduces and prioritizes
3. Shiny Development Agent → implements fix
4. Testing Agent → adds regression test
5. Code Review Agent → reviews fix
6. Linting & Style Agent → validates code quality
7. DevOps Agent → deploys hotfix
8. User Support Agent → notifies user
9. Documentation Agent → updates changelog
```

### Flow 3: Maintenance Cycle
```
1. Dependency Management Agent → checks for updates
2. Security Agent → scans for vulnerabilities
3. Testing Agent → runs full test suite
4. Performance Testing Agent → benchmarks
5. Monitoring Agent → reviews metrics
6. Documentation Maintenance Agent → updates docs
7. Code Review Agent → audits codebase health
```

---

## AUTOMATION HOOKS

### Pre-commit Hooks
```bash
#!/bin/bash
# .git/hooks/pre-commit

echo "Running style checks..."
Rscript scripts/style.R

echo "Running linter..."
Rscript scripts/lint.R

# Prevent commit if critical issues found
if [ $? -ne 0 ]; then
  echo "❌ Linting failed. Fix issues before committing."
  exit 1
fi
```

### GitHub Actions Workflows
```yaml
# .github/workflows/ci-tests.yml
name: CI Tests

on:
  pull_request:
    branches: [main, master]
  push:
    branches: [main, master]

jobs:
  lint-and-style:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: r-lib/actions/setup-r@v2
      - name: Restore renv
        run: Rscript -e "renv::restore()"
      - name: Lint code
        run: Rscript scripts/lint.R
      - name: Check style
        run: Rscript scripts/style.R
      - uses: actions/upload-artifact@v3
        with:
          name: lint-report
          path: lint-report.txt

  test-and-coverage:
    runs-on: ubuntu-latest
    needs: lint-and-style
    steps:
      - uses: actions/checkout@v3
      - uses: r-lib/actions/setup-r@v2
      - name: Restore renv
        run: Rscript -e "renv::restore()"
      - name: Run tests
        run: Rscript scripts/test.R
      - name: Generate coverage
        run: Rscript scripts/coverage.R
      - uses: codecov/codecov-action@v3
        with:
          files: ./coverage.xml

  security-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run security audit
        run: Rscript -e "oysteR::audit_installed_packages()"
```

---

## AGENT COMMUNICATION MATRIX

| Agent | Communicates With | Information Exchanged |
|-------|------------------|----------------------|
| Product Planning | UI/UX Design, Data Architecture | Requirements, specs |
| Data Architecture | Backend Logic, Shiny Development | Schema, validation rules |
| UI/UX Design | Shiny Development, Accessibility | Designs, layouts |
| Shiny Development | Testing, Code Review, Performance | Code, tests |
| Testing | Code Review, Bug Triage | Test results, coverage |
| Code Review | All Development Agents | Feedback, approvals |
| DevOps | Monitoring, Security | Deployments, infrastructure |
| Monitoring | Bug Triage, Performance | Metrics, errors |
| User Support | Bug Triage, Documentation | Issues, feedback |
| Documentation | All Agents | Updates needed |

---

## METRICS & KPIs

### Development Metrics
- **Cycle Time:** Time from feature request to production
- **Code Coverage:** Percentage of code covered by tests (target: >80%)
- **Code Quality:** Lint issues per 1000 lines of code
- **Technical Debt:** Hours of identified tech debt

### Operations Metrics
- **Uptime:** Application availability (target: 99.9%)
- **Response Time:** P95 response time for visualizations (target: <2s)
- **Error Rate:** Errors per 1000 requests (target: <0.1%)
- **Deployment Frequency:** Deployments per week

### User Metrics
- **User Satisfaction:** CSAT score from surveys
- **Support Tickets:** Number and resolution time
- **Feature Adoption:** Usage of new features
- **Session Duration:** Average time users spend in app

---

## TOOLING RECOMMENDATIONS

### Development
- **IDE:** RStudio with `shiny` and `lintr` plugins
- **Version Control:** Git with GitHub
- **Linting:** `lintr` package
- **Formatting:** `styler` package
- **Testing:** `testthat`, `shinytest2`
- **Profiling:** `profvis`, `microbenchmark`

### Operations
- **CI/CD:** GitHub Actions
- **Monitoring:** `logger` for logs, custom Shiny metrics
- **Error Tracking:** Sentry (optional)
- **Analytics:** Google Analytics or Plausible (privacy-focused)

### Collaboration
- **Documentation:** Markdown in `docs/`
- **Project Management:** GitHub Projects or Jira
- **Communication:** Slack, Microsoft Teams, or Discord

---

## FUTURE ENHANCEMENTS

### Short-term (1-3 months)
- [ ] Implement `shinytest2` snapshot tests
- [ ] Add performance metrics instrumentation
- [ ] Create user guide with screenshots
- [ ] Set up automated dependency scanning

### Medium-term (3-6 months)
- [ ] Introduce accessibility scanning with `pa11y`
- [ ] Implement A/B testing framework
- [ ] Add export functionality (PDF reports)
- [ ] Create admin dashboard for monitoring

### Long-term (6-12 months)
- [ ] Multi-language support (i18n)
- [ ] API for programmatic access
- [ ] Mobile-responsive redesign
- [ ] Real-time data streaming support
- [ ] Machine learning predictions for usage patterns

---

## REVISION HISTORY

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2024-01-XX | Initial version with 5 agents | Team |
| 2.0 | 2025-11-08 | Comprehensive lifecycle coverage with 20 agents | Claude Code |

---

**Keep this document updated as processes, tools, and team structures evolve.**
