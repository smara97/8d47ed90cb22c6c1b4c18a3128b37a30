# <!--

# Pull Request Template - Video RAG System

PURPOSE:
Standardized template for pull requests to ensure consistent code review
process and comprehensive change documentation for the Video RAG system.

GUIDELINES:

- Provide clear, concise descriptions of all changes
- Include technical implementation details for complex changes
- Document any breaking changes or migration requirements
- Ensure all testing requirements are met before submission
- Link related issues and provide context for reviewers

============================================================================
-->

## Summary

Brief description of changes made in this PR.

## Type of Change

- [ ] ✨ **Feature**: New functionality or enhancement
- [ ] 🐛 **Bug Fix**: Correction of existing functionality
- [ ] 📚 **Documentation**: Updates to documentation or comments
- [ ] ♻️ **Refactoring**: Code restructuring without functional changes
- [ ] ✅ **Tests**: Addition or modification of test cases
- [ ] 🔧 **Chore**: Maintenance tasks, dependency updates, tooling

## Technical Implementation

Describe the technical approach, architectural decisions, and implementation details.

### Key Changes

- List major code modifications and their rationale
- Document new dependencies or service integrations
- Explain configuration or environment changes

## Testing Strategy

### Automated Testing

- [ ] Unit tests added/updated for new functionality
- [ ] Integration tests pass with Kafka message flow
- [ ] Health checks verified for all services
- [ ] Performance tests confirm acceptable response times

### Manual Testing

- [ ] Functional testing completed for changed features
- [ ] Cross-service integration verified
- [ ] Error handling tested for edge cases

## Quality Assurance

- [ ] Code follows project style guidelines (black, flake8)
- [ ] Self-review completed with attention to edge cases
- [ ] Documentation updated for public APIs
- [ ] Security best practices followed
- [ ] CI pipeline passes all automated checks

## Breaking Changes

- [ ] No breaking changes
- [ ] Breaking changes documented with migration guide
- [ ] Backward compatibility maintained where possible

## Related Issues

Closes #[issue_number]
