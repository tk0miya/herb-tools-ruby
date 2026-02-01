# herb-tools-ruby Design Documentation

This directory contains architectural design documents for the herb-tools-ruby project.

## Documents

### [architecture.md](./architecture.md)
Overall system architecture and high-level design decisions.

**Contents:**
- Gem structure and dependencies
- Component responsibilities
- Design principles (SRP, DIP, OCP)
- Design patterns (Registry, Visitor, Strategy, Factory)
- Error handling conventions
- Processing flow overview

**Audience:** Developers who need to understand the overall system structure and architectural decisions.

### [herb-config-design.md](./herb-config-design.md)
Detailed design for the configuration management gem.

**Contents:**
- Component structure (Loader, Validator, Schema, Defaults, LinterConfig, FormatterConfig)
- RBS interface definitions for all classes
- Configuration search and merge behavior
- Validation rules and error handling
- Public API usage patterns

**Audience:** Developers implementing configuration-related features or integrating with herb-config.

### [herb-core-design.md](./herb-core-design.md)
Detailed design for the shared core utilities gem.

**Contents:**
- Component structure (FileDiscovery, PatternMatcher)
- RBS interface definitions for all classes
- Glob pattern matching behavior
- Public API usage patterns

**Audience:** Developers implementing file discovery or pattern matching features.

### [herb-lint-design.md](./herb-lint-design.md)
Detailed design for the ERB template linter.

**Contents:**
- Component structure (CLI, Runner, Linter, RuleRegistry, Rules, Reporters)
- Data structures (Offense, LintResult, AggregatedResult)
- RBS interface definitions for all classes
- Directive handling (`herb:disable`, `herb:linter ignore`, meta-rules)
- Rule implementation patterns using Herb::Visitor
- Reporter interface and implementations
- Processing flow and component interactions

**Audience:** Developers implementing linter features, custom rules, directive handling, or reporters.

### [printer-design.md](./printer-design.md)
Detailed design for the herb-printer gem: AST-to-source-code printer infrastructure.

**Contents:**
- Component structure (PrintContext, Base, IdentityPrinter)
- RBS interface definitions for all classes
- Node handling patterns for all 28 AST node types
- Lossless round-trip design and error handling
- Public API usage patterns and extension points
- Rationale for separate gem (TypeScript parity, separation of concerns)

**Audience:** Developers implementing printer features, custom printers, or integrating AST serialization into herb-format.

### [herb-format-design.md](./herb-format-design.md)
Detailed design for the ERB template formatter.

**Contents:**
- Component structure (CLI, Runner, Formatter, RewriterRegistry, Engine, Rewriters)
- Data structures (FormatResult, AggregatedResult)
- RBS interface definitions for all classes
- Rewriter implementation patterns (pre/post phases)
- Engine formatting rules and serialization
- Processing flow and component interactions

**Audience:** Developers implementing formatter features, custom rewriters, or formatting rules.

## Design Principles

All design documents follow these principles:

1. **Interface-focused**: Uses RBS (Ruby Signature) format for type definitions
2. **Responsibility-driven**: Describes WHAT each component does, not HOW
3. **Pattern-oriented**: Documents design patterns (interface vs class, inheritance, composition)
4. **API examples included**: Shows simple usage patterns to illustrate interfaces
5. **No implementation logic**: Avoids if/else, loops, and business logic in examples

## Type Definitions

All interfaces are defined using RBS format:

```rbs
# Interface for abstract contracts (duck typing)
interface _Reporter
  def report: (AggregatedResult result) -> void
end

# Class for concrete implementations
class DetailedReporter
  include _Reporter

  @output: IO

  def initialize: (?io: IO) -> void
  def report: (AggregatedResult result) -> void
end
```

### Conventions

- **`interface _Name`**: Abstract contracts (note the `_` prefix)
- **`class Name`**: Concrete implementations
- **`module Name`**: Namespaces or modules with module methods
- **`attr_reader name: Type`**: Read-only attributes
- **`?param: Type`**: Optional parameters
- **`Type?`**: Nullable types
- **`-> void`**: No return value

## Integration with Herb Gem

These designs integrate with the [Herb parser gem](https://github.com/marcoroth/herb):

- **AST Nodes**: Uses `Herb::AST::Node` and related types
- **Visitor Pattern**: Extends `Herb::Visitor` with visit_*_node methods
- **Location**: Uses `Herb::Location` for source position tracking
- **Parsing**: Calls `Herb.parse(source)` for template parsing

## Related Documentation

- [Requirements](../requirements/README.md) - Functional specifications
- [Herb gem repository](https://github.com/marcoroth/herb) - Reference parser implementation
- [RBS documentation](https://github.com/ruby/rbs) - Type signature syntax

## Maintenance

When updating these documents:

1. **Keep interfaces stable**: Changes to public interfaces should be rare and well-justified
2. **Document design decisions**: Explain WHY a particular approach was chosen
3. **Use RBS consistently**: All type signatures should follow RBS syntax
4. **Avoid implementation details**: Focus on architecture, not code
5. **Update all related docs**: Keep cross-references accurate

## Questions or Feedback

For questions about the design or to propose changes:

1. Review the relevant design document first
2. Check if your question is answered in the requirements documents
3. Consider creating a design discussion issue with your proposal
