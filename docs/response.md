# Response

Every request made using the client will return a `Monday::Response` object. This object consists of the following methods:

#### `status`

This is the returned HTTP status code.

#### `body`

This is the response body.

#### `headers`

This is the response header.

#### `success?`

This returns true or false based on the status code and the response body.

Sometimes when the application handles the exceptions, the API will return a `200` status code, but the body will return the error message.
