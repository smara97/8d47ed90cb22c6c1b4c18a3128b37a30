# Documentation Organization Rule

## Documentation Location

All documentation files (_.md, _.rst, \*.txt guides) must be placed in the `.docs/` directory.

## Structure

```
.docs/
├── README.md                    # Main project documentation
├── ENTERPRISE_FEATURES.md       # Enterprise production features
├── KAFKA_INTEGRATION_TESTING.md # Kafka testing guide
├── MAKEFILE_USAGE.md           # Makefile commands reference
└── architecture/               # Architecture diagrams and specs
```

## Rules

- No documentation files in project root
- All guides, READMEs, and documentation in `.docs/`
- Keep project root clean with only essential files
- Reference documentation from root with relative paths
