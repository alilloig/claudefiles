Analyze this repository and create tailored GitHub issue and PR templates.

## Step 1: Repository Analysis

Read the README.md and examine the top-level directory structure. Determine:

1. **Project Type**: library, application, documentation, learning materials, CLI tool, API, monorepo, etc.
2. **Tech Stack**: languages, frameworks, and tools used
3. **Structure**: how the codebase is organized (modules, packages, services)
4. **Existing Patterns**: contribution guidelines, existing templates, or conventions already in place
5. **Target Audience**: who contributes to this project (developers, learners, end-users)

## Reference: Project Type → Issue Types

| Project Type | Likely Issue Types |
|--------------|-------------------|
| Library/SDK | Bug reports, API issues, feature requests, documentation gaps, type errors |
| Application | Bugs, UI/UX issues, feature requests, performance problems, crashes |
| Documentation | Broken links, typos, outdated content, unclear explanations |
| Learning Materials | Code errors, confusing explanations, missing topics, broken examples |
| CLI Tool | Command errors, installation issues, feature requests, compatibility |
| API | Endpoint bugs, auth issues, rate limiting, documentation |

## Step 2: Create Tailored Templates

Based on your analysis, create these files in `.github/`:

### `.github/ISSUE_TEMPLATE/bug-report.md`

Frontmatter:
- `name`: Adapt to project (e.g., "Report an Issue" for docs, "Bug Report" for code)
- `about`: Brief description
- `title`: Prefix like `'[Bug] '` or `'[Module X] '`
- `labels`: `fix` or `bug`

Sections:
- **Issue Type**: Checkboxes for common issues in this project type
  - Code projects: crash, incorrect behavior, performance, security
  - Documentation: broken link, typo, outdated info, unclear explanation
  - Libraries: API issue, type error, compatibility
- **Location**: Where in the project (module, file, endpoint, page)
- **Description**: What's wrong
- **Environment** (for code projects): OS, version, etc.
- **Suggested Fix**: Optional

### `.github/ISSUE_TEMPLATE/feature-request.md`

Frontmatter:
- `name`: Adapt to project ("Content Request" for docs, "Feature Request" for apps)
- `labels`: `enhancement`

Sections:
- **Request Type**: Checkboxes relevant to project
  - Apps: new feature, improvement, UI/UX, integration
  - Docs: new topic, more examples, diagrams, tutorials
  - Libraries: new API, enhancement, better types
- **Description**: What to add/change
- **Motivation**: Why it's useful
- **Suggested Implementation**: Optional

### `.github/pull_request_template.md`

**Important**: Place this at `.github/pull_request_template.md`, NOT inside ISSUE_TEMPLATE/

Sections:
- **Summary**: What changed
- **Type of Change**: Checkboxes (fix, feature, docs, refactor, breaking change)
- **Affected Areas**: Which parts of the project
- **Checklist**: Tailored to project
  - Code: tests pass, linting, no breaking changes
  - Docs: links valid, examples work, follows style
  - Libraries: types updated, changelog entry, backwards compatible
- **Related Issues**: Links to issues

## Guidelines

- Use HTML comments `<!-- -->` for instructions (hidden when submitted)
- Keep templates concise - too long discourages contributions
- Use `- [ ]` checkboxes for categorization
- Include sensible title prefixes in frontmatter (e.g., `title: '[Bug] '`)
- Use appropriate labels in frontmatter (`fix`, `bug`, `enhancement`, etc.)
- Match terminology to the project's domain
- Tailor language to the contributor audience
- Mark optional sections as "(optional)"

## Output

Create all template files directly. After creating them, briefly explain what you customized based on your repository analysis.
