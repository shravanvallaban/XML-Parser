# XmlParser

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

# XML Parser API Documentation

This API allows users to upload XML files, parse them for plaintiff and defendant information, and search for uploaded files. The API adheres to the JSON API specification (https://jsonapi.org).

## Table of Contents

1. [Base URL](#base-url)
2. [Authentication](#authentication)
3. [Content Type](#content-type)
4. [Endpoints](#endpoints)
   - [Upload XML File](#upload-xml-file)
   - [Search Files](#search-files)
5. [Error Handling](#error-handling)
6. [Resource Objects](#resource-objects)
7. [Notes](#notes)

## Base URL

All URLs referenced in the documentation have the following base:

http://localhost:4000/api

## Authentication

This API currently does not require authentication.

## Content Type

All requests should include the following header:
Accept: application/vnd.api+json

All responses will have the content type: 
Content-Type: application/vnd.api+json

## Endpoints

### Upload XML File

Upload and parse an XML file.

- **URL:** `/files`
- **Method:** `POST`
- **Content-Type:** `multipart/form-data`

#### Request Body

| Field | Type | Description |
|-------|------|-------------|
| file  | File | The XML file to upload |

#### Success Response

- **Code:** 201 CREATED
- **Content:**

```json
{
  "data": {
    "type": "file",
    "id": "1",
    "attributes": {
      "upload_file_name": "example.xml",
      "uploaded_time": "2023-05-20T12:34:56Z",
      "plaintiff": "John Doe",
      "defendants": "ACME Corporation"
    }
  }
}

Error Response
  Code: 422 UNPROCESSABLE ENTITY
  Content:

{
  "errors": [
    {
      "status": "422",
      "title": "Unprocessable Entity",
      "detail": "Invalid file type. Please upload an XML file."
    }
  ]
}

Search Files
Search for uploaded files by filename.
  URL: /files
  Method: GET
  URL Params:
    Required: filename=[string]


Success Response
  Code: 200 OK
  Content:

{
  "data": [
    {
      "type": "file",
      "id": "1",
      "attributes": {
        "upload_file_name": "example.xml",
        "uploaded_time": "2023-05-20T12:34:56Z",
        "plaintiff": "John Doe",
        "defendants": "ACME Corporation"
      }
    },
    // ... up to 5 results
  ]
}

No Results Response
If no files are found, an empty data array is returned:
  Code: 200 OK
  Content:

{
  "data": []
}

Error Handling
The API uses the following error codes:
  400 Bad Request
  404 Not Found
  422 Unprocessable Entity
  500 Internal Server Error

Error responses will include an errors array with objects containing status, title, and detail fields. Some errors may include additional meta information.

Example
{
  "errors": [
    {
      "status": "422",
      "title": "Unprocessable Entity",
      "detail": "Invalid file format. Please upload a valid XML file."
    }
  ]
}

### Resource Objects

#### File Object

| Field                        | Type   | Description                                                      |
|------------------------------|--------|------------------------------------------------------------------|
| id                           | string | Unique identifier for the file                                   |
| type                         | string | Always "file"                                                    |
| attributes.upload_file_name  | string | Name of the uploaded file                                        |
| attributes.uploaded_time     | string | ISO 8601 formatted timestamp of when the file was uploaded       |
| attributes.plaintiff         | string | Extracted plaintiff information from the XML file                |
| attributes.defendants        | string | Extracted defendant information from the XML file                |


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
