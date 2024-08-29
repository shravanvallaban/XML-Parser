# lib/xml_parser_web/controllers/api/file_controller.ex
defmodule XmlParserWeb.Api.FileController do
  use XmlParserWeb, :controller
  require Logger
  alias XmlParser.Repo
  alias XmlParser.Schemas.File, as: FileSchema
  alias XmlParser.XmlParser
  import Ecto.Query

  @allowed_content_types ["text/xml", "application/xml"]

  @doc """
  Handles the file upload, parsing, and storage process.
  """
  def create(conn, %{"file" => file_params}) do
    with :ok <- validate_file_type(file_params),
         {:ok, file_content} <- read_uploaded_file(file_params),
         {:ok, parsed_data} <- parse_xml_safely(file_content),
         :ok <- validate_parsed_data(parsed_data),
         {:ok, file} <- save_file_data(file_params, parsed_data) do

      conn
      |> put_status(:created)
      |> json(%{
        message: "File successfully uploaded and processed",
        uploaded_time: file.uploaded_time,
        upload_file_name: file.upload_file_name,
        plaintiff: file.plaintiff,
        defendants: file.defendants
      })
    else
      {:error, :invalid_file_type} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Invalid file type. Please upload an XML file."})

      {:error, :invalid_file} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Invalid file format. Please upload a valid XML file."})

      {:error, :no_data_extracted} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Unable to extract plaintiff or defendant information from the file."})

      {:error, :invalid_data} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "The file does not contain valid plaintiff and defendant information."})

      {:error, %Ecto.Changeset{} = changeset} ->
        errors = format_changeset_errors(changeset)
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Failed to save file data", details: errors})

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "An unexpected error occurred", details: reason})
    end
  end

  @doc """
  Searches for files based on filename.
  """
  def search(conn, %{"filename" => filename}) do
    query = from f in FileSchema,
      where: ilike(f.upload_file_name, ^"%#{filename}%")

    files = Repo.all(query)

    case files do
      [] ->
        conn
        |> put_status(:not_found)
        |> json(%{message: "No files found matching the search criteria."})
      _ ->
        conn
        |> put_status(:ok)
        |> json(%{files: files})
    end
  end

   # Validates the file type
   defp validate_file_type(%{content_type: content_type}) do
    if content_type in @allowed_content_types do
      :ok
    else
      {:error, :invalid_file_type}
    end
  end

  # Reads the content of the uploaded file
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

  # Safely parses the XML content
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

  # Validates that both plaintiff and defendant data are present
  defp validate_parsed_data(%{plaintiffs: plaintiffs, defendants: defendants}) do
    if is_binary(plaintiffs) and is_binary(defendants) and
       plaintiffs != "" and defendants != "" do
      :ok
    else
      {:error, :invalid_data}
    end
  end

  # Saves the parsed file data to the database
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
end
