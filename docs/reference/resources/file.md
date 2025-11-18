# Add Files (Assets)

Add files to board Columns and Updates (comments) via the `client.file` resource.

::: tip <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="16" x2="12" y2="12"></line><line x1="12" y1="8" x2="12.01" y2="8"></line></svg>What are Columns?</span>
Files can be added to a Column or an item Update (Comments).
:::

## Methods

### add_file_to_column

Adds a file to a column on a board.

```ruby
client.file.add_file_to_column(args: {}, select: ["id"])
```

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `args` | Hash | `{}` | Creation arguments (required) |
| `select` | Array | `["id", "title", "description"]` | Fields to retrieve |

**Required args:**
- `item_id` - Integer - Item ID
- `column_id` - String - Column ID
- `file` - File - File to be added to the column.

**Optional args:**
- `defaults` - String (JSON) - Default column settings

**Returns:** `Monday::Response`

**Note**
- `UploadIO` is from the multipart-post gem that is included.

**Example:**

```ruby
// UploadIO is from the multipart-post gem that is included.
response = client.file.add_file_to_column(args: {
  item_id: 1234567890,
  column_id: 'file_mkxsq27k',
  file: UploadIO.new(
    File.open('/path/to/polarBear.jpg'),
    'image/jpeg',
    'polarBear.jpg'
  )
})

if response.success?
  monday_file_id = response.body.dig("data", "add_file_to_column", "id")
  puts "Added file #{monday_file_id} to column"
end
```

**GraphQL:** `mutation { add_file_to_column { ... } }`

**See:** [monday.com add_file_to_column](https://developer.monday.com/api-reference/reference/assets-1#add-file-to-column)


### add_file_to_update

Adds a file to an item's Update (comments).

```ruby
client.file.add_file_to_update(args: {}, select: ["id"])
```

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `args` | Hash | `{}` | Creation arguments (required) |
| `select` | Array | `["id", "title", "description"]` | Fields to retrieve |

**Required args:**
- `item_id` - Integer - Item ID
- `file` - File - File to be added to the column.

**Optional args:**
- `defaults` - String (JSON) - Default column settings

**Note**
- `UploadIO` is from the multipart-post gem that is included.

**Returns:** `Monday::Response`

**Example:**

```ruby
// UploadIO is from the multipart-post gem that is included.
response = client.file.add_file_to_update(args: {
  update_id: 1234567890,
  file: UploadIO.new(
    File.open('/path/to/polarBear.jpg'),
    'image/jpeg',
    'polarBear.jpg'
  )
})

if response.success?
  monday_file_id = response.body.dig("data", "add_file_to_update", "id")
  puts "Added file #{monday_file_id} to update"
end
```

**GraphQL:** `mutation { add_file_to_update { ... } }`

**See:** [monday.com add_file_to_update](https://developer.monday.com/api-reference/reference/assets-1#add-file-to-update)


### clear_file_column

Clears all files in an item's File column. This is a helper method for files and you could also use the column.change_value to clear the column as well.


```ruby
client.file.clear_file_column(args: {}, select: ["id"])
```

**Parameters:**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `args` | Hash | `{}` | Arguments (required) |
| `select` | Array | `["id"]` | Fields to retrieve |

**Required args:**
- `board_id` - Integer or String - Board to clear updates from
- `item_id` - Integer or String - Item to clear updates from
- `column_id` - String - Column to clear updates from

**Returns:** `Monday::Response`

::: warning <span style="display: inline-flex; align-items: center; gap: 6px;"><svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>Destructive Operation</span>
This permanently deletes all files from the item's File column. This cannot be undone.
:::

**Example:**

```ruby
response = client.file.clear_file_column(
  args: {
    board_id: 1234,
    item_id: 5678,
    column_id: 'file_1234'
  }
)

    "data": {
        "change_column_value": {
            "id": "18370875011"
        }
    },

result = response.body.dig("data", "change_column_value", "id")
# => 123456
```

**GraphQL:** `mutation { change_column_value { ... } }`

**See:** [monday.com change_column_value](https://developer.monday.com/api-reference/reference/columns#change-column-value)


## Response Structure

All methods return a `Monday::Response` object. Access data using:

```ruby
response.success?  # => true/false
response.status    # => 200
response.body      # => Hash with GraphQL response
```

### Typical Response Pattern

```ruby
response = client.column.create(
  args: {
    board_id: 1234567890,
    title: "Status",
    column_type: :color
  }
)

if response.success?
  column = response.body.dig("data", "create_column")
  # Work with column
else
  # Handle error
end
```

## Constants

### DEFAULT_SELECT

Default fields returned by all methods:

```ruby
["id"]
```

## Error Handling

Common errors when working with columns:

- `Monday::AuthorizationError` - Invalid or missing API token
- `Monday::InvalidRequestError` - Invalid board ID or column ID
- `Monday::Error` - Invalid column type, invalid field, or other API errors

**Example:**

```ruby
begin
  response = client.file.add_file_to_column(
    args: {
      item_id: 123,
      column_id: "file_123",
      file: 'some_file_string' # Invalid file/stream
    }
  )
rescue Monday::InvalidRequestError => e
  puts "Error: #{e.message}"
end
```

See the [Error Handling guide](/guides/advanced/errors) for more details.

## Related Resources

- [Column](/reference/resources/column) - Columns on items
- [Update](/reference/resources/update) - Updates (comments) on items

## External References

- [monday.com Columns API](https://developer.monday.com/api-reference/reference/columns)
- [GraphQL API Overview](https://developer.monday.com/api-reference/docs/introduction-to-graphql)
- [Column Types](https://support.monday.com/hc/en-us/articles/115005483545-All-About-Columns)
