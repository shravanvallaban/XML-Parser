# lib/xml_parser_web/controllers/api/file_controller.ex
defmodule XmlParserWeb.Api.FileController do
  use XmlParserWeb, :controller
  require Logger
  alias XmlParser.Repo
  alias XmlParser.Schemas.File, as: FileSchema
  alias XmlParser.XmlParser
  import Ecto.Query

  # def create(conn, %{"file" => file_params}) do
  #   with {:ok, file_content} <- read_file(file_params),
  #        {:ok, parsed_data} <- safe_parse(file_content),
  #        {:ok, file} <- create_file(file_params, parsed_data) do

  #     conn
  #     |> put_status(:created)
  #     |> json(%{
  #       message: "Successfully Uploaded",
  #       uploaded_time: file.uploaded_time,
  #       upload_file_name: file.upload_file_name,
  #       plaintiff: file.plaintiff,
  #       defendants: file.defendants
  #     })
  #   else
  #     {:error, :no_data_extracted} ->
  #       Logger.error("No plaintiff or defendant data could be extracted from the XML")
  #       conn
  #       |> put_status(:unprocessable_entity)
  #       |> json(%{error: "No plaintiff or defendant data could be extracted from the XML"})
  #       |> halt()
  #     {:error, %Ecto.Changeset{} = changeset} ->
  #       Logger.error("Invalid data: #{inspect(changeset.errors)}")
  #       conn
  #       |> put_status(:unprocessable_entity)
  #       |> json(%{error: "Invalid data", details: changeset_error_to_string(changeset)})
  #       |> halt()
  #     {:error, reason} ->
  #       Logger.error("Unexpected error: #{inspect(reason)}")
  #       conn
  #       |> put_status(:internal_server_error)
  #       |> json(%{error: "An unexpected error occurred", details: inspect(reason)})
  #       |> halt()
  #   end
  # end

  def create(conn, %{"file" => file_params}) do
    with {:ok, file_content} <- read_file(file_params),
         {:ok, parsed_data} <- safe_parse(file_content),
         {:ok, file} <- create_file(file_params, parsed_data) do

      conn
      |> put_status(:created)
      |> json(%{
        message: "Successfully Uploaded",
        uploaded_time: file.uploaded_time,
        upload_file_name: file.upload_file_name,
        plaintiff: file.plaintiff,
        defendants: file.defendants
      })
    else
      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: reason})
    end
  end

  def search(conn, %{"filename" => filename}) do
    query = from f in FileSchema,
      where: ilike(f.upload_file_name, ^"%#{filename}%")

    files = Repo.all(query)

    conn
    |> put_status(:ok)
    |> json(%{files: files})
  end


  defp read_file(file_params) do
    case File.read(file_params.path) do
      {:ok, content} ->
        Logger.info("File read successfully")
        {:ok, content}
      {:error, reason} ->
        Logger.error("Failed to read file: #{inspect(reason)}")
        {:error, "Failed to read uploaded file: #{inspect(reason)}"}
    end
  end

  defp safe_parse(file_content) do
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
      {:error, "Failed to parse XML content: #{inspect(e)}"}
  end

  defp create_file(file_params, parsed_data) do
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

  defp changeset_error_to_string(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.reduce("", fn {k, v}, acc ->
      joined_errors = Enum.join(v, "; ")
      "#{acc}#{k}: #{joined_errors}\n"
    end)
  end
end
