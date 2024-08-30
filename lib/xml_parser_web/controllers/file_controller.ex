# lib/xml_parser_web/controllers/api/file_controller.ex
defmodule XmlParserWeb.Api.FileController do
  use XmlParserWeb, :controller
  require Logger
  alias XmlParser.Repo
  alias XmlParser.Schemas.File, as: FileSchema
  alias XmlParser.XmlParser
  alias XmlParserWeb.Api.FileView
  import Ecto.Query

  # List of allowed MIME types for uploaded files
  @allowed_content_types ["text/xml", "application/xml"]

  @doc """
  Handles the file upload, parsing, and storage process.
  This function orchestrates the entire process of file handling:
  1. Validates the file type
  2. Reads the uploaded file
  3. Parses the XML content
  4. Validates the parsed data
  5. Saves the file data to the database
  """
  def create(conn, %{"file" => file_params}) do
    with :ok <- validate_file_type(file_params),
         {:ok, file_content} <- read_uploaded_file(file_params),
         {:ok, parsed_data} <- parse_xml_safely(file_content),
         :ok <- validate_parsed_data(parsed_data),
         {:ok, file} <- save_file_data(file_params, parsed_data) do

      # If all steps succeed, return a success response
      conn
      |> put_status(:created)
      |> put_resp_content_type("application/vnd.api+json")
      |> json(FileView.render("show.json", %{data: file}))
    else
      # Handle various error cases
      {:error, :invalid_file_type} ->
        send_error_response(conn, :unprocessable_entity, "Invalid file type. Please upload an XML file.")

      {:error, :invalid_file} ->
        send_error_response(conn, :unprocessable_entity, "Invalid file format. Please upload a valid XML file.")

      {:error, :no_data_extracted} ->
        send_error_response(conn, :unprocessable_entity, "Unable to extract plaintiff or defendant information from the file.")

      {:error, :invalid_data} ->
        send_error_response(conn, :unprocessable_entity, "The file does not contain valid plaintiff and defendant information.")

      {:error, %Ecto.Changeset{} = changeset} ->
        send_error_response(conn, :unprocessable_entity, "Failed to save file data", format_changeset_errors(changeset))

      {:error, reason} ->
        send_error_response(conn, :internal_server_error, "An unexpected error occurred", reason)
    end
  end

  @doc """
  Searches for files based on filename and returns the top 5 most recent results.
  This function performs a case-insensitive search on the upload_file_name field,
  orders the results by upload time (descending), and limits the results to 5.
  """
  def search(conn, %{"filename" => filename}) do
    query = from f in FileSchema,
      where: ilike(f.upload_file_name, ^"%#{filename}%"),
      order_by: [desc: f.uploaded_time],
      limit: 5

    files = Repo.all(query)

    conn
    |> put_status(:ok)
    |> render("index.json", data: files)
  end

  # Private helper functions

  # Validates the file type against the list of allowed MIME types
   defp validate_file_type(%{content_type: content_type}) do
    if content_type in @allowed_content_types do
      :ok
    else
      {:error, :invalid_file_type}
    end
  end

  # Reads the content of the uploaded file
  # Returns {:ok, content} if successful, {:error, :invalid_file} otherwise
  defp read_uploaded_file(file_params) do
    case File.read(file_params.path) do
      {:ok, content} ->
        Logger.info("File read successfully")
        {:ok, content}
      {:error, reason} ->
        Logger.error("Failed to read file: #{inspect(reason)}")
        {:error, :invalid_file}
    end
  end

  # Safely parses the XML content using the XmlParser module
  # Returns {:ok, parsed_data} if successful, {:error, reason} otherwise
  defp parse_xml_safely(file_content) do
    case XmlParser.parse(file_content) do
      %{plaintiffs: "Error extracting plaintiff", defendants: "Error extracting defendants"} ->
        Logger.error("Failed to extract plaintiff and defendant data")
        {:error, :no_data_extracted}
      parsed_data ->
        Logger.info("XML parsed successfully: #{inspect(parsed_data)}")
        {:ok, parsed_data}
    end
  rescue
    e ->
      Logger.error("Error parsing XML: #{inspect(e)}")
      {:error, :invalid_file}
  end

  # Validates that both plaintiff and defendant data are present and non-empty
  defp validate_parsed_data(%{plaintiffs: plaintiffs, defendants: defendants}) do
    if is_binary(plaintiffs) and is_binary(defendants) and
       plaintiffs != "" and defendants != "" do
      :ok
    else
      {:error, :invalid_data}
    end
  end

  # Saves the parsed file data to the database
  # Returns {:ok, file} if successful, {:error, changeset} otherwise
  defp save_file_data(file_params, parsed_data) do
    changeset = %FileSchema{}
    |> FileSchema.changeset(%{
      upload_file_name: file_params.filename,
      uploaded_time: DateTime.utc_now(),
      plaintiff: parsed_data.plaintiffs,
      defendants: parsed_data.defendants
    })

    case Repo.insert(changeset) do
      {:ok, file} ->
        Logger.info("File record created successfully: #{inspect(file)}")
        {:ok, file}
      {:error, changeset} ->
        Logger.error("Error creating file record: #{inspect(changeset.errors)}")
        {:error, changeset}
    end
  end

  # Formats changeset errors into a more readable format
  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map(fn {k, v} -> "#{k}: #{Enum.join(v, ", ")}" end)
    |> Enum.join("; ")
  end

  # Sends an error response with the given status, message, and optional details
  defp send_error_response(conn, status, message, details \\ nil) do
    conn
    |> put_status(status)
    |> put_resp_content_type("application/vnd.api+json")
    |> json(FileView.render("error.json", %{error: message, details: details}))
  end
end
