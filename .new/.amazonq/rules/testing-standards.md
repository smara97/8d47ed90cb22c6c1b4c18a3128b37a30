# Testing Standards Rules

## Test Coverage Requirements

- Analyze all changes in current branch/PR for test coverage gaps
- Identify unit tests needed to exercise new functionality
- Suggest integration tests for component interactions
- Ensure edge cases and error conditions are tested

## Test Development Process

1. Review code changes and identify testable functionality
2. Describe what each proposed test would exercise
3. Create tests incrementally, one at a time
4. Run each test to ensure it passes before proceeding
5. Verify test actually exercises intended functionality
6. Review test code for clarity and completeness

## Test Quality Standards

- Tests should be isolated and independent
- Use descriptive test names that explain the scenario
- Include setup, execution, and assertion phases
- Mock external dependencies appropriately
- Test both success and failure scenarios
- Maintain test performance and avoid flaky tests

## Testing Tools Integration

- Use project-appropriate testing frameworks
- Integrate with CI/CD pipeline for automated testing
- Generate coverage reports and maintain minimum thresholds
- Include performance and load testing where applicable
