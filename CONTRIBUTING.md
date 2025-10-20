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

## Commit message guidelines

* Use present tense ("Add feature" not "Added feature")
* Use the imperative mood ("Move file to..." not "Moves file to...")
* Limit the first line to 70 characters or less.
* Reference issues and pull requests after the first line.
* Try to follow [conventional commits](https://www.conventionalcommits.org/en/v1.0.0/)
