# GraphQL and the monday.com API

This document explains GraphQL fundamentals and how they relate to the monday.com API and the monday_ruby gem.

## What is GraphQL?

GraphQL is a query language for APIs and a runtime for executing those queries. Unlike traditional REST APIs where the server determines the structure of responses, GraphQL allows clients to request exactly the data they need, nothing more and nothing less.

Developed by Facebook in 2012 and open-sourced in 2015, GraphQL addresses common pain points in API design:

- **Over-fetching**: REST endpoints often return more data than needed
- **Under-fetching**: Multiple REST requests may be needed to gather related data
- **API versioning**: GraphQL schemas evolve without breaking existing queries
- **Strong typing**: The GraphQL type system provides clear contracts between client and server

## Why monday.com Uses GraphQL

monday.com chose GraphQL for its API because of the platform's inherently relational and flexible nature:

1. **Complex data relationships**: Boards contain groups, groups contain items, items have columns, columns have values, and all these entities are interconnected
2. **Flexible data structures**: Different boards have different column types and configurations
3. **Client efficiency**: Applications can fetch exactly what they need in a single request
4. **Schema introspection**: The API is self-documenting, making it easier for developers to explore

## GraphQL vs REST APIs

### REST Approach

In a REST API, you might need multiple requests to get board data:

```
GET /boards/123
GET /boards/123/groups
GET /boards/123/items
GET /items/456/column_values
```

Each endpoint returns a fixed structure, often including data you don't need.

### GraphQL Approach

With GraphQL, you make a single request specifying exactly what you want:

```graphql
query {
  boards(ids: [123]) {
    name
    groups {
      title
      items {
        name
        column_values {
          id
          text
        }
      }
    }
  }
}
```

The response structure matches your query structure, containing only the requested fields.

## Query vs Mutation Operations

GraphQL distinguishes between two primary operation types:

### Queries

Queries are read-only operations that fetch data. They're similar to HTTP GET requests but with precise field selection:

```graphql
query {
  boards(ids: [123, 456]) {
    id
    name
    state
  }
}
```

Queries can be executed in parallel and are generally safe to retry or cache.

### Mutations

Mutations modify server-side data (create, update, delete). They're analogous to POST, PUT, PATCH, and DELETE in REST:

```graphql
mutation {
  create_board(board_name: "New Project", board_kind: public) {
    id
    name
  }
}
```

Mutations are executed sequentially in the order specified, ensuring predictable side effects.

## GraphQL Schema and Types

The GraphQL schema defines the API's type system - what data is available and how it's structured.

### Core Concepts

- **Types**: Define objects (like `Board`, `Item`, `User`) with specific fields
- **Fields**: Properties on types that can be queried
- **Scalars**: Primitive types like `String`, `Int`, `Boolean`, `ID`
- **Enums**: Fixed sets of allowed values
- **Non-null**: Fields that are guaranteed to return a value (marked with `!`)

### monday.com's Schema

The monday.com schema reflects its data model:

- `Board` type has fields like `name`, `groups`, `items`, `columns`
- `Item` type has fields like `name`, `column_values`, `group`, `board`
- `ColumnValue` is an interface with different implementations for each column type

This strongly-typed schema enables:
- Validation at query time
- Intelligent autocomplete in development tools
- Clear documentation of available fields
- Type safety in client applications

## Field Selection in GraphQL

Field selection is one of GraphQL's most powerful features. You specify exactly which fields you want in your response.

### Simple Selection

```graphql
query {
  boards(ids: [123]) {
    id
    name
  }
}
```

Returns only `id` and `name` for each board.

### Nested Selection

```graphql
query {
  boards(ids: [123]) {
    name
    groups {
      title
      items {
        name
      }
    }
  }
}
```

Traverse relationships by selecting fields on nested objects.

### Why This Matters

- **Performance**: Smaller payloads mean faster responses
- **Bandwidth**: Critical for mobile applications
- **Clarity**: The query documents exactly what data the application uses
- **Backend optimization**: Servers can optimize based on what's requested

## Arguments and Variables

GraphQL fields can accept arguments to filter, sort, or modify their behavior.

### Inline Arguments

```graphql
query {
  boards(ids: [123, 456], limit: 10) {
    name
  }
}
```

### Variables

For dynamic queries, use variables instead of hardcoding values:

```graphql
query GetBoards($boardIds: [ID!]!) {
  boards(ids: $boardIds) {
    name
  }
}
```

Variables are passed separately from the query:

```json
{
  "boardIds": [123, 456]
}
```

This separation enables:
- Query reuse with different values
- Better caching (queries are the same, only variables change)
- Automatic input validation
- Protection against injection attacks

## How monday_ruby Abstracts GraphQL

The monday_ruby gem provides a Ruby-friendly interface to the GraphQL API while preserving its flexibility.

### Query Building

Instead of writing GraphQL strings, you use Ruby methods:

```ruby
client.board.query(
  args: { ids: [123, 456] },
  select: ["id", "name", { groups: ["title", "id"] }]
)
```

The gem converts this to:

```graphql
query{boards(ids: [123, 456]){id name groups{title id}}}
```

### Why This Abstraction?

1. **Ruby idioms**: Use Ruby hashes and arrays instead of GraphQL syntax
2. **Dynamic queries**: Build queries programmatically based on runtime conditions
3. **Error handling**: Translate GraphQL errors into Ruby exceptions
4. **Reduced boilerplate**: Authentication and HTTP handling are automatic
5. **Type safety**: Ruby's dynamic nature with GraphQL's strict types

### The Trade-off

The abstraction means you're not writing raw GraphQL, which:
- **Advantage**: Faster development, more Ruby-like code
- **Disadvantage**: You still need to understand GraphQL concepts to use the API effectively

## Why Understanding GraphQL Helps

Even with monday_ruby's abstraction, GraphQL knowledge is valuable:

1. **Field selection**: Knowing what fields are available and how they relate
2. **Query optimization**: Understanding how to request only necessary data
3. **Error interpretation**: GraphQL errors reference fields and types
4. **Rate limiting**: GraphQL complexity calculations affect your limits
5. **Documentation**: monday.com's API docs use GraphQL terminology
6. **Debugging**: Network inspection shows GraphQL queries and responses
7. **Advanced features**: Aliases, fragments, directives require GraphQL understanding

## GraphQL Complexity and Rate Limiting

GraphQL's flexibility creates a challenge: queries can be arbitrarily complex and expensive.

### Complexity Calculation

monday.com assigns complexity points to each field based on computational cost:

- Simple scalar fields: Low complexity (1-5 points)
- Relationships: Medium complexity (10-20 points)
- Mutations: Higher complexity (20-50+ points)

A query's total complexity is the sum of all requested fields.

### Rate Limits

monday.com enforces limits based on:
- **Complexity budget**: Maximum complexity per time window
- **Request frequency**: Number of requests per minute
- **Account tier**: Different limits for different subscription levels

### Optimization Strategies

Understanding complexity helps you:
- Select only necessary fields to reduce complexity
- Batch multiple operations into single queries
- Use pagination to spread load across requests
- Cache frequently accessed data
- Monitor complexity through response headers

## monday.com's GraphQL API Specifics

### API Version

monday.com versions its API (e.g., "2023-07", "2024-01"). Versions are specified via headers and control:
- Available fields and types
- Deprecation of old features
- Changes to field behavior

The monday_ruby gem allows configuring the version:

```ruby
client = Monday::Client.new(token: "...", version: "2024-01")
```

### Mutation Response Patterns

monday.com mutations return the created or modified object, allowing you to:
1. Confirm the operation succeeded
2. Get the new object's ID
3. Fetch updated field values

```graphql
mutation {
  create_item(board_id: 123, item_name: "Task") {
    id
    name
    created_at
  }
}
```

### Error Responses

GraphQL errors are returned in the response alongside data (if any):

```json
{
  "data": { ... },
  "errors": [
    {
      "message": "Field 'invalid_field' doesn't exist",
      "locations": [{"line": 2, "column": 3}]
    }
  ]
}
```

This allows partial success: some fields may return data while others error.

### Nested Mutations

monday.com supports mutations that affect multiple related entities:

```graphql
mutation {
  create_board(board_name: "Project") {
    id
    groups {
      id
      title
    }
  }
}
```

The mutation creates a board and returns its auto-generated groups in one operation.

## Conclusion

GraphQL is fundamental to how monday.com's API works. While monday_ruby abstracts the syntax, understanding GraphQL concepts - queries vs mutations, field selection, arguments, complexity, and the type system - enables you to use the gem effectively and efficiently.

The monday.com API's GraphQL implementation prioritizes flexibility and efficiency, allowing you to fetch complex, interconnected data in single requests while maintaining strong typing and introspection capabilities. This design philosophy directly influences how you structure queries and mutations through the monday_ruby gem.
