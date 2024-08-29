# XML Parser and Legal Document Analyzer

This project is a web application that allows users to upload XML files containing legal documents, extracts plaintiff and defendant information, and provides a search functionality for uploaded files.

## Table of Contents

1. [Project Overview](#project-overview)
2. [Backend Setup](#backend-setup)
3. [Frontend Setup](#frontend-setup)
4. [Running the Application](#running-the-application)
5. [API Endpoints](#api-endpoints)
6. [Plaintiff and Defendant Extraction Algorithm](#plaintiff-and-defendant-extraction-algorithm)

## Project Overview

The application consists of two main parts:
1. A Phoenix backend that handles XML parsing, data extraction, and storage.
2. A React frontend that provides a user interface for file upload and search.

## Backend Setup

The backend is built with Elixir and the Phoenix framework.

### Prerequisites

- Elixir (version 1.14 or later)
- Phoenix framework
- PostgreSQL

### Installation

1. Clone the repository:
   ```bash
   git clone [your-repo-url]
   cd [your-repo-name]
	```

2. Install dependencies:

```bash
mix deps.get
```

3. Set up the database:

* Ensure PostgreSQL is running.
* Update the database configuration in config/dev.exs if necessary.
* Run migrations:
```
	mix ecto.setup
```

4. Create a .env file in the config directory and add your database configuration:
```
POSTGRES_USERNAME=your_username
POSTGRES_PASSWORD=your_password
POSTGRES_HOST=localhost
POSTGRES_DB=xml_parser_dev
POSTGRES_PORT=5432
```

## Frontend Setup
The frontend is built with React.
### Prerequisites

* Node.js (version 14 or later)
* npm or yarn

### Installation

1. Navigate to the root directory:
```
mkdir assets
cd assets
```
2. Install dependencies:
```
npm install
```

## Running the Application

1. Start the Phoenix server: go to root dir
```
mix phx.server
```
2. In a separate terminal, start the frontend development server:
```
cd assets
npm start
```
3. Visit http://localhost:3000 in your web browser to access the application.

## API Endpoints
The backend provides the following API endpoints:

1. Upload XML File

* URL: /api/files
* Method: POST
* Content-Type: multipart/form-data

2. Search Files

* URL: /api/files?filename=<search_term>
* Method: GET

For detailed API documentation, refer to the API Documentation file that follows later

## Plaintiff and Defendant Extraction Algorithm
The algorithm for extracting plaintiff and defendant information from the XML files is implemented in the XmlParser module. Here's an overview of the process:

### Plaintiff Extraction

1. The XML content is parsed into blocks, paragraphs, and lines.
2. The algorithm searches for a line containing the word "Plaintiff,".
3. Once found, it looks backwards for a line containing "COUNTY", "County", or "county".
4. The content between the county line and the plaintiff line is extracted.
5. The algorithm then looks for keywords like "individual" or "inclusive" within this content.
6. If found, it extracts the content from the start of the line with the keyword to the end.
7. If no keywords are found, it returns the entire extracted content.

### Defendant Extraction

1.The XML content is parsed into blocks, paragraphs, and lines.
2. The algorithm searches for "v." or "vs." to identify the start of defendant information.
3. It then looks for "Defendants." to identify the end of defendant information.
4. The content between these markers is extracted.
5. The algorithm refines the extracted content by:
* Looking for text starting with an uppercase letter.
* Including content up to "inclusive," or "inclusive." if present.
* If not present, it includes content up to but not including "Defendants."

6. The last word is removed if it appears to be incomplete (doesn't end with punctuation).

This algorithm aims to handle various formats of legal documents while extracting the most relevant information about plaintiffs and defendants.

## Screenshots

![Alt text](/screenshots/1.png?raw=true "Search")

![Alt text](/screenshots/2.png?raw=true "Upload 1")

![Alt text](/screenshots/3.png?raw=true "Upload 2")


# XML Parser API Documentation

This document provides a comprehensive guide to the XML Parser application API endpoints, detailing the process of uploading XML files, extracting plaintiff and defendant information, and searching for uploaded files.

## API Endpoints

### 1. Upload XML File

Uploads an XML file and extracts plaintiff and defendant information.

- **URL**: `/files`
- **Method**: `POST`
- **Content-Type**: `multipart/form-data`
- **Accept**: `application/vnd.api+json`

#### Request

The request should include a file upload field named `file`.

#### Response

##### Success Response (201 Created)

```json
{
  "data": {
    "type": "files",
    "id": "1",
    "attributes": {
      "upload_file_name": "example.xml",
      "uploaded_time": "2023-06-15T10:30:00Z",
      "plaintiff": "John Doe",
      "defendants": "ABC Corporation, Jane Smith"
    }
  }
}
```

##### Error Responses

###### 422 Unprocessable Entity

Returned when the request is malformed, missing required parameters, the uploaded file is not a valid XML file, or when plaintiff/defendant information cannot be extracted.

```json
{
  "errors": [
    {
      "status": "422",
      "title": "Unprocessable Entity",
      "detail": "Error message describing the specific issue"
    }
  ]
}
```

###### 500 Internal Server Error

Returned when an unexpected error occurs on the server.

```json
{
  "errors": [
    {
      "status": "500",
      "title": "Internal Server Error",
      "detail": "An unexpected error occurred while processing the file."
    }
  ]
}
```

### 2. Search Files

Searches for uploaded files based on filename.

- **URL**: `/files`
- **Method**: `GET`
- **Accept**: `application/vnd.api+json`

#### Query Parameters

- `filename`: The filename to search for (partial match)

#### Response

##### Success Response (200 OK)

```json
{
  "data": [
    {
      "type": "files",
      "id": "1",
      "attributes": {
        "upload_file_name": "example1.xml",
        "uploaded_time": "2023-06-15T10:30:00Z",
        "plaintiff": "John Doe",
        "defendants": "ABC Corporation, Jane Smith"
      }
    },
    {
      "type": "files",
      "id": "2",
      "attributes": {
        "upload_file_name": "example2.xml",
        "uploaded_time": "2023-06-15T11:00:00Z",
        "plaintiff": "Alice Johnson",
        "defendants": "XYZ Inc., Bob Brown"
      }
    }
  ]
}
```

##### Error Response

###### 500 Internal Server Error

Returned when an unexpected error occurs on the server.

```json
{
  "errors": [
    {
      "status": "500",
      "title": "Internal Server Error",
      "detail": "An unexpected error occurred while searching for files."
    }
  ]
}
```

## Error Handling

All error responses follow the JSON API specification for error objects. The general structure is:

```json
{
  "errors": [
    {
      "status": "HTTP_STATUS_CODE",
      "title": "Brief, human-readable summary of the problem",
      "detail": "More detailed explanation specific to this occurrence of the problem"
    }
  ]
}
```

## Notes

- The API adheres to the JSON API specification (https://jsonapi.org/).
- All responses use the `application/vnd.api+json` content type.
- The search endpoint returns the top 5 most recent results matching the filename query.
- Uploaded files must be in XML format with the content type `text/xml` or `application/xml`.
- The server uses UTC for all timestamps.
- File IDs are unique and auto-incrementing integers.


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
