# Testing Best Practices

Testing code that integrates with external APIs presents unique challenges. You need to balance test reliability, speed, and realism while managing dependencies on external services. This guide explores testing philosophies and patterns for the monday_ruby gem.

## Testing Philosophy for API Integrations

Testing API integrations requires a different mindset than testing pure business logic.

### The Core Tension

**Reliability vs. Realism**: Tests should be:
- **Fast**: Run in seconds, not minutes
- **Reliable**: Pass consistently, not dependent on network or API state
- **Isolated**: Not affected by other tests or external changes
- **Realistic**: Actually test your integration, not just mocks

You can't maximize all four simultaneously. The art of testing API integrations is finding the right balance for your needs.

### The Testing Pyramid for API Integrations

```
        /\
       /  \    E2E (Real API) - Slow, realistic
      /    \
     /------\  Integration (VCR) - Medium speed, recorded reality
    /        \
   /----------\ Unit (Mocks) - Fast, isolated
```

**Unit tests (70%)**: Test business logic with mocked API responses
**Integration tests (25%)**: Test API interactions with VCR cassettes
**E2E tests (5%)**: Occasional real API calls to verify cassettes are current

This distribution gives you fast feedback (unit tests) while ensuring your integration actually works (VCR/E2E tests).

## Unit vs Integration vs End-to-End Tests

### Unit Tests (Mocked)

Test your code's logic without making real API calls:

```ruby
RSpec.describe BoardSync do
  it 'processes board data correctly' do
    mock_response = {
      'data' => {
        'boards' => [
          { 'id' => '123', 'name' => 'Test Board' }
        ]
      }
    }

    allow(client.board).to receive(:query).and_return(mock_response)

    sync = BoardSync.new(client)
    result = sync.fetch_boards

    expect(result.first.name).to eq('Test Board')
  end
end
```

**Pros:**
- Very fast (milliseconds)
- No network dependencies
- Full control over responses (easy to test edge cases)
- No API quota usage

**Cons:**
- Doesn't test actual API integration
- Mocks can drift from reality
- Brittle (breaks when implementation changes)

**When to use**: Testing business logic, error handling, data transformation

### Integration Tests (VCR)

Test with real API responses recorded to cassettes:

```ruby
RSpec.describe 'Board API', :vcr do
  it 'fetches boards with correct fields' do
    response = client.board.query(
      ids: [12345],
      select: ['id', 'name']
    )

    expect(response.dig('data', 'boards')).to be_an(Array)
    expect(response.dig('data', 'boards', 0, 'name')).to be_a(String)
  end
end
```

**Pros:**
- Tests actual integration (real request/response structure)
- Fast (replays from cassettes)
- Deterministic (same cassette, same result)
- Safe (no accidental API mutations)

**Cons:**
- Cassettes can become outdated
- Harder to test error scenarios
- Requires initial real API call to record
- Cassettes need maintenance

**When to use**: Testing API client methods, query building, response parsing

### End-to-End Tests (Real API)

Make actual API calls:

```ruby
RSpec.describe 'Board API', :e2e do
  it 'creates and fetches a board' do
    board = client.board.create(
      board_name: "Test Board #{Time.now.to_i}"
    )

    board_id = board.dig('data', 'create_board', 'id')

    fetched = client.board.query(ids: [board_id])
    expect(fetched.dig('data', 'boards', 0, 'id')).to eq(board_id)

    # Cleanup
    client.board.delete(board_id: board_id)
  end
end
```

**Pros:**
- Tests real integration (nothing mocked)
- Catches API changes immediately
- Validates current API behavior

**Cons:**
- Slow (network latency)
- Unreliable (network issues, API changes, rate limits)
- Uses API quota
- Requires cleanup (can leave test data)
- Can't run offline

**When to use**: Periodic verification, pre-release smoke tests, cassette validation

## Mocking vs VCR vs Real API Calls

### When to Use Each

| Scenario | Approach | Reason |
|----------|----------|--------|
| Testing error handling logic | Mock | Need to control exact error responses |
| Testing retry mechanisms | Mock | Need to simulate multiple failure scenarios |
| Testing request building | VCR | Need realistic request structure |
| Testing response parsing | VCR | Need realistic response structure |
| Verifying API hasn't changed | Real API | Need current truth |
| CI/CD pipeline | VCR | Need speed and reliability |
| Local development | VCR | Don't waste API quota |
| Pre-production checks | Real API | Final verification |

### Combining Approaches

You don't have to choose just one. Use tags to organize tests:

```ruby
# spec/spec_helper.rb
RSpec.configure do |config|
  config.around(:each, :real_api) do |example|
    VCR.turn_off!
    example.run
    VCR.turn_on!
  end
end

# Test with VCR by default
RSpec.describe 'Board API', :vcr do
  it 'fetches board' do
    # Uses VCR cassette
  end
end

# Specific test uses real API
RSpec.describe 'Board API', :real_api do
  it 'validates API compatibility' do
    # Makes real API call
  end
end
```

Run VCR tests normally, real API tests occasionally:

```bash
# Normal run (VCR only)
bundle exec rspec

# Full run including real API tests
bundle exec rspec --tag real_api
```

## Testing with VCR Cassettes

VCR is the monday_ruby gem's primary testing approach. Understanding how to use it effectively is crucial.

### How VCR Works

1. **First run**: Makes real HTTP request, records to cassette file
2. **Subsequent runs**: Replays response from cassette, no HTTP request
3. **Cassette matching**: Matches requests by URI, method, and body

### Basic VCR Configuration

```ruby
# spec/spec_helper.rb
require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  config.hook_into :webmock
  config.configure_rspec_metadata!

  # Filter sensitive data
  config.filter_sensitive_data('<MONDAY_TOKEN>') do |interaction|
    interaction.request.headers['Authorization']&.first
  end

  # Match requests by URI, method, and body
  config.default_cassette_options = {
    match_requests_on: [:method, :uri, :body]
  }
end
```

### Recording Cassettes

```ruby
RSpec.describe 'Board API', :vcr do
  it 'fetches boards' do
    # First run: makes real API call, saves to
    # spec/fixtures/vcr_cassettes/Board_API/fetches_boards.yml
    response = client.board.query(ids: [12345])
    expect(response).to be_a(Monday::Response)
  end
end
```

### Filtering Sensitive Data

**Critical**: Don't commit API tokens to cassettes!

```ruby
VCR.configure do |config|
  # Replace token in request headers
  config.filter_sensitive_data('<MONDAY_TOKEN>') do |interaction|
    interaction.request.headers['Authorization']&.first
  end

  # Replace token in request body (if present)
  config.filter_sensitive_data('<MONDAY_TOKEN>') do
    ENV['MONDAY_TOKEN']
  end

  # Replace account IDs
  config.filter_sensitive_data('<ACCOUNT_ID>') do
    ENV['MONDAY_ACCOUNT_ID']
  end
end
```

Cassettes will contain `<MONDAY_TOKEN>` instead of actual credentials.

### Updating Cassettes

Cassettes become outdated when APIs change. Update them by deleting and re-recording:

```bash
# Delete all cassettes
rm -rf spec/fixtures/vcr_cassettes/

# Re-record (requires valid API token in .env)
bundle exec rspec
```

Or update selectively:

```bash
# Delete specific cassette
rm spec/fixtures/vcr_cassettes/Board_API/fetches_boards.yml

# Re-record just that test
bundle exec rspec spec/monday/resources/board_spec.rb:10
```

### Cassette Maintenance

**When to update cassettes:**
- API response structure changes
- Adding new test cases
- Testing new API features
- Before major releases (verify API compatibility)

**Best practice**: Review cassette changes in PRs. New fields or changed structures may indicate breaking API changes.

## Test Isolation and Idempotency

Tests should be independent and repeatable.

### Test Isolation Principles

1. **No shared state**: Each test sets up its own data
2. **No order dependencies**: Tests pass in any order
3. **Clean up**: Remove test data after execution

### Achieving Isolation with Mocks

```ruby
RSpec.describe BoardService do
  let(:client) { instance_double(Monday::Client) }
  let(:board_resource) { instance_double(Monday::Resources::Board) }

  before do
    allow(client).to receive(:board).and_return(board_resource)
  end

  it 'fetches board' do
    allow(board_resource).to receive(:query).and_return(mock_data)

    service = BoardService.new(client)
    result = service.fetch

    expect(result).to eq(expected_result)
  end

  # Each test is isolated - mocks are fresh
  it 'handles errors' do
    allow(board_resource).to receive(:query).and_raise(Monday::Error)

    service = BoardService.new(client)
    expect { service.fetch }.to raise_error(Monday::Error)
  end
end
```

### Achieving Isolation with VCR

VCR cassettes are read-only, so they're inherently isolated:

```ruby
RSpec.describe 'Board API', :vcr do
  it 'fetches board 1' do
    response = client.board.query(ids: [12345])
    # Uses cassette: Board_API/fetches_board_1.yml
  end

  it 'fetches board 2' do
    response = client.board.query(ids: [67890])
    # Uses cassette: Board_API/fetches_board_2.yml
    # Independent of first test
  end
end
```

### Achieving Idempotency with Real API

Real API tests are trickier—you need cleanup:

```ruby
RSpec.describe 'Board lifecycle', :real_api do
  after do
    # Cleanup: delete any boards created during test
    @created_boards&.each do |board_id|
      client.board.delete(board_id: board_id)
    rescue Monday::Error
      # Ignore errors (board may already be deleted)
    end
  end

  it 'creates and deletes board' do
    @created_boards = []

    board = client.board.create(board_name: 'Test Board')
    board_id = board.dig('data', 'create_board', 'id')
    @created_boards << board_id

    # Test operations...

    client.board.delete(board_id: board_id)
    @created_boards.delete(board_id)
  end
end
```

**Better approach**: Use unique identifiers to avoid collisions:

```ruby
it 'creates board with unique name' do
  board_name = "Test Board #{SecureRandom.uuid}"
  board = client.board.create(board_name: board_name)
  # Even if cleanup fails, won't conflict with other tests
end
```

## Testing Error Scenarios

Error handling is critical but often under-tested.

### Mocking Error Responses

```ruby
RSpec.describe 'error handling' do
  it 'handles authorization errors' do
    allow(client).to receive(:make_request)
      .and_raise(Monday::AuthorizationError.new('Invalid token'))

    expect { fetch_board }.to raise_error(Monday::AuthorizationError)
  end

  it 'handles rate limiting' do
    allow(client).to receive(:make_request)
      .and_raise(Monday::ComplexityError.new('Rate limit exceeded'))

    expect { fetch_board }.to raise_error(Monday::ComplexityError)
  end

  it 'handles network timeouts' do
    allow(client).to receive(:make_request)
      .and_raise(Timeout::Error)

    expect { fetch_board }.to raise_error(Timeout::Error)
  end
end
```

### Testing Error Recovery

```ruby
it 'retries on transient errors' do
  call_count = 0

  allow(client).to receive(:make_request) do
    call_count += 1
    raise Monday::InternalServerError if call_count < 3
    mock_success_response
  end

  result = fetch_with_retry
  expect(call_count).to eq(3)
  expect(result).to eq(mock_success_response)
end

it 'gives up after max retries' do
  allow(client).to receive(:make_request)
    .and_raise(Monday::InternalServerError)

  expect { fetch_with_retry(max_attempts: 3) }
    .to raise_error(Monday::InternalServerError)
end
```

### VCR Error Cassettes

You can record error responses too:

```ruby
# First run: trigger actual error (e.g., invalid ID)
# VCR records the error response

RSpec.describe 'error responses', :vcr do
  it 'handles not found error' do
    expect {
      client.board.query(ids: [999999999])
    }.to raise_error(Monday::ResourceNotFoundError)
  end
end
```

The cassette contains the actual error response structure.

## Testing Pagination Logic

Pagination is complex and error-prone. Test it thoroughly.

### Mocking Paginated Responses

```ruby
RSpec.describe 'pagination' do
  it 'fetches all pages' do
    page1 = { 'data' => { 'items' => [{ 'id' => 1 }, { 'id' => 2 }] } }
    page2 = { 'data' => { 'items' => [{ 'id' => 3 }, { 'id' => 4 }] } }
    page3 = { 'data' => { 'items' => [] } }  # Empty = end

    allow(client.item).to receive(:query_by_board)
      .with(hash_including(page: 1)).and_return(page1)
    allow(client.item).to receive(:query_by_board)
      .with(hash_including(page: 2)).and_return(page2)
    allow(client.item).to receive(:query_by_board)
      .with(hash_including(page: 3)).and_return(page3)

    all_items = fetch_all_items
    expect(all_items.count).to eq(4)
  end

  it 'handles empty first page' do
    empty = { 'data' => { 'items' => [] } }

    allow(client.item).to receive(:query_by_board)
      .and_return(empty)

    all_items = fetch_all_items
    expect(all_items).to be_empty
  end
end
```

### Testing Pagination Edge Cases

```ruby
it 'stops at max pages to prevent infinite loops' do
  # Mock pagination that never ends
  non_empty = { 'data' => { 'items' => [{ 'id' => 1 }] } }
  allow(client.item).to receive(:query_by_board)
    .and_return(non_empty)

  # Should stop at max_pages
  all_items = fetch_all_items(max_pages: 10)
  expect(all_items.count).to eq(10)
end

it 'handles errors mid-pagination' do
  page1 = { 'data' => { 'items' => [{ 'id' => 1 }] } }

  allow(client.item).to receive(:query_by_board)
    .with(hash_including(page: 1)).and_return(page1)
  allow(client.item).to receive(:query_by_board)
    .with(hash_including(page: 2)).and_raise(Monday::Error)

  expect { fetch_all_items }.to raise_error(Monday::Error)
end
```

## Testing Rate Limiting Behavior

Rate limiting is hard to test realistically without actually hitting rate limits.

### Mocking Rate Limit Errors

```ruby
it 'backs off when rate limited' do
  allow(client).to receive(:make_request)
    .and_raise(Monday::ComplexityError)
    .exactly(3).times
    .then.return(mock_success_response)

  expect(self).to receive(:sleep).with(2)
  expect(self).to receive(:sleep).with(4)
  expect(self).to receive(:sleep).with(8)

  result = fetch_with_backoff
  expect(result).to eq(mock_success_response)
end
```

### Testing Rate Limit Tracking

```ruby
RSpec.describe ComplexityTracker do
  it 'allows requests within budget' do
    tracker = ComplexityTracker.new(budget_per_minute: 1000)

    expect(tracker.can_request?(cost: 500)).to be true
    tracker.record(cost: 500)
    expect(tracker.can_request?(cost: 400)).to be true
  end

  it 'blocks requests exceeding budget' do
    tracker = ComplexityTracker.new(budget_per_minute: 1000)
    tracker.record(cost: 900)

    expect(tracker.can_request?(cost: 200)).to be false
  end

  it 'resets budget after time window' do
    tracker = ComplexityTracker.new(budget_per_minute: 1000)
    tracker.record(cost: 1000)

    Timecop.travel(Time.now + 61) do
      expect(tracker.can_request?(cost: 500)).to be true
    end
  end
end
```

Use `Timecop` or `travel_to` to test time-based logic without waiting.

## CI/CD Considerations

Running tests in CI/CD requires special considerations.

### VCR in CI

VCR cassettes make CI simple:

```yaml
# .github/workflows/test.yml
name: Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.2
          bundler-cache: true
      - run: bundle exec rspec
        # No API token needed - uses VCR cassettes
```

### Real API Tests in CI

If running real API tests in CI:

```yaml
jobs:
  test:
    steps:
      - run: bundle exec rspec
        env:
          MONDAY_TOKEN: ${{ secrets.MONDAY_TOKEN }}
          # Only run real API tests in certain conditions
      - run: bundle exec rspec --tag real_api
        if: github.event_name == 'schedule'  # Only in nightly runs
        env:
          MONDAY_TOKEN: ${{ secrets.MONDAY_TOKEN }}
```

### Cassette Validation in CI

Periodically verify cassettes are up-to-date:

```yaml
# Run weekly to catch API changes
on:
  schedule:
    - cron: '0 0 * * 0'  # Weekly

jobs:
  validate-cassettes:
    steps:
      - run: rm -rf spec/fixtures/vcr_cassettes
      - run: bundle exec rspec
        env:
          MONDAY_TOKEN: ${{ secrets.MONDAY_TOKEN }}
      - uses: peter-evans/create-pull-request@v4
        with:
          title: Update VCR cassettes
          body: Automated cassette update from CI
```

This creates a PR if cassettes change, allowing review before merging.

## Test Data Management

Managing test data is crucial for reliable tests.

### Fixture Data

Store mock responses as fixtures:

```ruby
# spec/fixtures/board_response.json
{
  "data": {
    "boards": [
      {"id": "123", "name": "Test Board"}
    ]
  }
}

# spec/spec_helper.rb
def load_fixture(name)
  JSON.parse(File.read("spec/fixtures/#{name}.json"))
end

# In tests
RSpec.describe 'BoardService' do
  it 'processes board data' do
    board_data = load_fixture('board_response')
    allow(client.board).to receive(:query).and_return(board_data)

    service = BoardService.new(client)
    result = service.process

    expect(result).to be_a(ProcessedBoard)
  end
end
```

### Factories for Test Data

Use factories for creating test objects:

```ruby
# spec/factories/monday_responses.rb
FactoryBot.define do
  factory :board_response, class: Hash do
    skip_create  # Don't persist

    sequence(:id) { |n| n.to_s }
    name { "Board #{id}" }

    initialize_with { attributes.stringify_keys }
  end
end

# In tests
let(:board) { build(:board_response, name: 'Custom Board') }
```

### Real API Test Data

For real API tests, use a dedicated test account:

```ruby
# config/test_data.yml
test_account:
  board_id: 12345
  item_id: 67890
  user_id: 11111

# spec/support/test_data.rb
def test_board_id
  YAML.load_file('config/test_data.yml')['test_account']['board_id']
end

# In tests
it 'fetches test board', :real_api do
  response = client.board.query(ids: [test_board_id])
  expect(response).to be_present
end
```

## Security in Tests

Tests often handle sensitive data. Protect it.

### Never Commit Tokens

```ruby
# .gitignore
.env
.env.test
spec/fixtures/vcr_cassettes/*  # If cassettes contain secrets

# Use environment variables
RSpec.describe 'API client' do
  let(:client) { Monday::Client.new(token: ENV['MONDAY_TOKEN']) }
end
```

### Filter Sensitive Data in VCR

```ruby
VCR.configure do |config|
  # Filter headers
  config.filter_sensitive_data('<TOKEN>') do |interaction|
    interaction.request.headers['Authorization']&.first
  end

  # Filter response data
  config.filter_sensitive_data('<EMAIL>') do |interaction|
    JSON.parse(interaction.response.body).dig('data', 'me', 'email') rescue nil
  end

  # Filter by pattern
  config.filter_sensitive_data('<API_KEY>') { ENV['MONDAY_TOKEN'] }
end
```

### Secure CI Secrets

```yaml
# GitHub Actions
jobs:
  test:
    steps:
      - run: bundle exec rspec
        env:
          MONDAY_TOKEN: ${{ secrets.MONDAY_TOKEN }}  # Encrypted secret
          # Never use ${{ secrets.MONDAY_TOKEN }} in commands that echo/log
```

### Review Cassettes Before Committing

```bash
# Check cassettes for sensitive data before committing
git diff spec/fixtures/vcr_cassettes/

# Look for:
# - Tokens in Authorization headers
# - Email addresses
# - Account IDs
# - User names
```

If found, update VCR filters and re-record cassettes.

## Key Takeaways

1. **Use the testing pyramid**: Mostly mocks (fast), some VCR (realistic), few real API calls (validation)
2. **VCR for integration tests**: monday_ruby's primary testing approach—fast and realistic
3. **Test error scenarios**: Don't just test happy paths
4. **Maintain test isolation**: Each test should be independent and idempotent
5. **Protect sensitive data**: Filter tokens from VCR cassettes, use environment variables
6. **Update cassettes regularly**: Verify API compatibility with periodic re-recording
7. **Test pagination thoroughly**: Edge cases like empty results and errors mid-pagination
8. **Mock time-based logic**: Use Timecop for testing rate limiting and time windows
9. **CI/CD-friendly**: VCR cassettes make tests fast and reliable in CI without API tokens
10. **Review cassette changes**: API changes may indicate breaking changes

Good tests give you confidence to refactor, add features, and upgrade dependencies. Invest time in your test suite—it pays dividends.
