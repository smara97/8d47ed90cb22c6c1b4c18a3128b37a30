# Git Workflow Rules

## Commit Standards

- Use conventional commit format with emojis: `emoji type: description`
- Required emojis by type:
  - `✨ feat:` - New features
  - `🐛 fix:` - Bug fixes
  - `📚 docs:` - Documentation
  - `♻️ refactor:` - Code refactoring
  - `✅ test:` - Tests
  - `🔧 chore:` - Maintenance
- Include detailed description of changes and reasoning
- Stage all modified files before committing
- Always push to origin after successful commit

## Code Quality

- Run appropriate linters/formatters before commits
- Fix all linting issues and security problems
- Follow project language conventions and style
- Ensure clean, simple APIs and readable code
- Address performance issues before submitting

## Pull Request Process

1. Format code using project-specific tools
2. Create descriptive commit with conventional format
3. Compare changes against base branch (main/develop)
4. Generate structured PR description with:
   - Summary of changes
   - Technical implementation details
   - Testing steps
   - Related issues/tickets
5. Use GitHub CLI for PR creation and management
