# Documentation Standards Rules

## Code Documentation Requirements

### Docblocks and Comments

- All classes must have comprehensive docblocks explaining purpose, usage, and examples
- All public methods/functions require docblocks with parameters, return values, and exceptions
- Complex algorithms and business logic must have inline comments explaining the approach
- Configuration files require header comments explaining purpose and usage

### Class and Property Documentation

- Class properties must have type hints and descriptive comments
- Environment variables must be documented with purpose and default values
- Constants and configuration values require explanatory comments
- Database models and schemas need field-level documentation

### File-Level Documentation

- All source files must start with header comments explaining file purpose
- Include author, creation date, and modification history where applicable
- Reference related files, dependencies, and architectural decisions
- Provide usage examples for utility files and modules

### API and Interface Documentation

- REST endpoints require OpenAPI/Swagger documentation
- Kafka topics and message schemas must be documented
- Docker services need comprehensive compose file comments
- Environment configuration requires detailed .env comments

## Documentation Quality Standards

- Use clear, concise language avoiding jargon
- Include practical examples and usage patterns
- Keep documentation synchronized with code changes
- Follow language-specific documentation conventions (JSDoc, Sphinx, etc.)
- Provide troubleshooting guides for complex components
