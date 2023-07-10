# Error Handling

Monday.com has a set of predefined errors and exceptions that are sent back from their GraphQL API. Refer to their [official documentation](https://developer.monday.com/api-reference/docs/errors) to know more about the error codes.

### Catching exceptions

If there is an error from the API, the library raises an exception. It's a best practice to catch and handle exceptions.

To catch an exception, use the `rescue` keyword. You can catch all the exceptions from the API using the `Monday::Error` class. However, it is recommended to catch specific exceptions using its subclasses and have a fallback rescue using `Monday::Error`.

```ruby
require "monday_ruby"

client = Monday::Client.new(token: <AUTH_TOKEN>)

def example
  res = client.boards
  puts res.body
rescue Monday::AuthorizationError => error
  puts "Authorization error: #{error.message}"
  puts "Error code: #{error.code}"
rescue Monday::Error => error
  puts "Other error: #{error.message}"
end
```

Along with the default status code exceptions, monday.com returns some other exceptions with `200` status code. This library handles those errors and raises exceptions accordingly.

#### `Monday::InternalServer Error`

This exception is raised when the server returns a `500` status code. Read more about what can cause this error on Monday.com's [official documentation](https://developer.monday.com/api-reference/docs/errors#internal-server-error).

#### `Monday::AuthorizationError`

This exception is raised when the server returns a `401` or a `403` status code. This can happen when the client is not authenticated, i.e., not configured with the token, or the token is incorrect.

This exception is also raised when the server returns a `200` status code but the body returns `UserUnauthorizedException` error code.

#### `Monday::RateLimitError`

This exception is raised when the server returns a `429` status code. This can happen when you exceed the rate limit, i.e., 5,000 requests per minute. Read more about their rate limit on their [official documentation](https://developer.monday.com/api-reference/docs/rate-limits).

#### `Monday::ResourceNotFoundError`

This exception is raised when the server returns a `404` status code. This can happen when you pass an invalid ID in the query.

This exception is also raised when the server returns a `200` status code but the body returns `ResourceNotFoundException` error code.

#### `Monday::ComplexityError`

This exception is raised when the server returns a `200` status code but the body returns  `ComplexityException` error code.

#### `Monday::InvalidRequestError`

This exception is raised when the server returns a `400` status code. This can happen when the query you pass is invalid.

This exception is also raised when the server returns a `200` status code but the body returns the following error codes:

1. `InvalidUserIdException`
2. `InvalidVersionException`
3. `InvalidColumnIdException`
4. `InvalidItemIdException`
5. `InvalidBoardIdException`
6. `InvalidArgumentException`
7. `CreateBoardException`
8. `ItemsLimitationException`
9. `ItemNameTooLongException`
10. `ColumnValueException`
11. `CorrectedValueException`

Read more about these specific exceptions on their [official API documentation](https://developer.monday.com/api-reference/docs/errors).
