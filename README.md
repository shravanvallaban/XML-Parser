# XmlParser

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).


# XML Parser Test Suite

This README provides information on how to run the test files for the XML Parser project and explains the purpose of each test file.

## Running Tests

To run all tests, use the following command in your terminal:

```
mix test
```

To run a specific test file, use:

```
mix test path/to/test_file.exs
```

## Test Files

### 1. file_test.exs

**Path**: `test/xml_parser/schemas/file_test.exs`

**Purpose**: Tests the `FileSchema` module, which is responsible for validating and creating changesets for file uploads.

**How to run**:
```
mix test test/xml_parser/schemas/file_test.exs
```

**What it tests**:
- Creation of valid changesets with proper attributes
- Required fields (upload_file_name, uploaded_time)
- Validation of plaintiff as a string
- Validation of defendants as a list of strings

### 2. file_controller_test.exs

**Path**: `test/xml_parser_web/controllers/api/file_controller_test.exs`

**Purpose**: Tests the `FileController` module, which handles file uploads and searches.

**How to run**:
```
mix test test/xml_parser_web/controllers/api/file_controller_test.exs
```

**What it tests**:
- Successful upload and processing of a valid XML file
- Error handling for invalid XML uploads
- File search functionality
- Handling of searches with no matching results

### 3. xml_parser_test.exs

**Path**: `test/xml_parser/xml_parser_test.exs`

**Purpose**: Tests the `XmlParser` module, which is responsible for parsing XML content.

**How to run**:
```
mix test test/xml_parser/xml_parser_test.exs
```

**What it tests**:
- Successful parsing of valid XML
- Error handling for invalid XML
- Handling of empty string input
- Handling of nil input

### 4. error_json_test.exs

**Path**: `test/xml_parser_web/error_json_test.exs`

**Purpose**: Tests the `ErrorJSON` module, which handles JSON responses for errors.

**How to run**:
```
mix test test/xml_parser_web/error_json_test.exs
```

**What it tests**:
- Rendering of 404 (Not Found) error responses
- Rendering of 500 (Internal Server Error) error responses

## Test Fixtures

Some tests use fixture files located in the `test/fixtures` directory:

- `test_file.xml`: A valid XML file used for testing successful parsing and uploads.
- `invalid_sample.xml`: An invalid XML file used for testing error handling.

Ensure these files are present and contain appropriate test data before running the tests.

## Note

Make sure you have all necessary dependencies installed and your database properly set up before running the tests. If you encounter any issues, check the project's main README for setup instructions or consult the project maintainers.
