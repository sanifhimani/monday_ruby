# Contributing

Thanks for taking the time to contribute!

The following is a set of guidelines for contributing to `monday_ruby`. These are mostly guidelines, not rules. Use your best judgment, and feel to propose changes to this document in a pull request.

## Your first code contribution

Unsure where to begin contributing? You can start by looking through `good first issue` and `help wanted` issues.

### Pull request

Please follow these steps to have your contribution considered:

1. Follow the [pull request template](PULL_REQUEST_TEMPLATE.md).
2. Follow the [commit guidelines](#commit-message-guidelines).
3. After you submit your pull request, verify that all the status checks are passing.

## Testing Guidelines

This project uses [VCR](https://github.com/vcr/vcr) to record HTTP interactions for tests. This means you **do not need a Monday.com API token** to run most tests or contribute to the project.

### Running Tests

To run the test suite:

```bash
bundle exec rake spec
```

All tests will use pre-recorded VCR cassettes stored in `spec/fixtures/vcr_cassettes/`.

### Working with VCR Cassettes

**For most contributions, you won't need to modify VCR cassettes.** The existing cassettes cover the current API functionality.

#### When You Need to Record New Cassettes

You only need to record new VCR cassettes when:
- Adding support for a **new API endpoint** that doesn't have existing test coverage
- Modifying an existing API call that changes the request/response structure

To record new cassettes:

1. Set your Monday.com API token as an environment variable:
   ```bash
   export MONDAY_TOKEN="your_token_here"
   ```

2. Delete the old cassette file (if updating an existing test):
   ```bash
   rm spec/fixtures/vcr_cassettes/your_cassette_name.yml
   ```

3. Run the specific test to generate a new cassette:
   ```bash
   bundle exec rspec spec/path/to/your_spec.rb
   ```

4. **Important:** Before committing, verify the cassette doesn't contain sensitive data:
   - VCR automatically filters the `Authorization` header
   - Check for any other sensitive information in the cassette file
   - Cassettes are committed to the repository

#### Testing New Features Without API Access

If you're adding a new feature but don't have API access to record cassettes:
1. Write your implementation and tests
2. Create a pull request noting that cassettes need to be recorded
3. A maintainer with API access will record the cassettes for you

### Code Quality

Run RuboCop to ensure code style compliance:

```bash
bundle exec rake rubocop
```

## Documentation

The project uses [VitePress](https://vitepress.dev/) to generate documentation from Markdown files. The documentation site is hosted at [https://sanifhimani.github.io/monday_ruby/](https://sanifhimani.github.io/monday_ruby/).

### When to Update Documentation

Update documentation when you:
- Add a new resource or method to the public API
- Change the behavior of existing methods
- Add new features or configuration options
- Fix bugs that affect documented behavior

### Documentation Structure

Documentation follows the [Diataxis framework](https://diataxis.fr):

- **Tutorial** (`docs/tutorial/`) - Learning-oriented, gets users started
- **How-to Guides** (`docs/guides/`) - Task-oriented, solves specific problems
- **Reference** (`docs/reference/`) - Information-oriented, describes the API
- **Explanation** (`docs/explanation/`) - Understanding-oriented, explains concepts

### Adding/Updating Documentation

Documentation files are located in the `docs/` directory:

```
docs/
├── .vitepress/
│   └── config.mjs          # Navigation and site configuration
├── guides/                 # How-to guides
│   ├── boards/
│   ├── items/
│   ├── columns/
│   └── advanced/
├── reference/              # API reference
│   ├── resources/
│   └── client.md
├── explanation/            # Conceptual documentation
└── tutorial/               # Getting started tutorial
```

#### Steps to Update Documentation:

1. **Find or create the appropriate file** based on what you're documenting
2. **Follow the existing format** - look at similar documentation files for examples
3. **Test your code examples** - all examples should be runnable and accurate
4. **Update navigation** if adding new pages - edit `docs/.vitepress/config.mjs`
5. **Build locally** to preview changes:

```bash
cd docs
npm install  # First time only
npm run dev  # Start local dev server
```

Visit `http://localhost:5173/monday_ruby/` to preview your changes.

6. **Check for broken links** before submitting:

```bash
cd docs
npm run build  # Build will fail if there are dead links
```

#### Documentation Guidelines:

- **Code examples must be accurate** - verify against VCR test fixtures or real API
- **Include practical examples** - show real-world usage, not just syntax
- **Be consistent** - follow the style and tone of existing documentation
- **No emojis** - maintain professional tone in documentation
- **Link related pages** - help users discover relevant documentation
- **Keep examples self-contained** - users should be able to copy-paste and run

#### Example Documentation Pattern:

```markdown
# Resource Name

Brief description of what this resource does.

## Methods

### method_name

Description of what the method does.

\`\`\`ruby
# Example code that actually works
client = Monday::Client.new(token: ENV["MONDAY_TOKEN"])
response = client.resource.method_name(args: {})
\`\`\`

**Parameters:**
- List parameters and their types

**Returns:** Description of return value

**See:** Link to monday.com API docs
```

### Deploying Documentation

Documentation is automatically deployed via GitHub Actions when changes are merged to the `main` branch. You don't need to manually deploy.

## Commit message guidelines

* Use present tense ("Add feature" not "Added feature")
* Use the imperative mood ("Move file to..." not "Moves file to...")
* Limit the first line to 70 characters or less.
* Reference issues and pull requests after the first line.
* Try to follow [conventional commits](https://www.conventionalcommits.org/en/v1.0.0/)
