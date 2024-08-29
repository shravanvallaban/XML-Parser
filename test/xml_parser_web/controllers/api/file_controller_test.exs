# test/xml_parser_web/controllers/api/file_controller_test.exs
defmodule XmlParserWeb.Api.FileControllerTest do
  use XmlParserWeb.ConnCase, async: true
  alias XmlParser.Repo
  alias XmlParser.Schemas.File, as: FileSchema

  @valid_xml_path "test/fixtures/test_file.xml"
  @invalid_xml_path "test/fixtures/invalid_sample.xml"


  describe "POST /api/files" do
    test "successfully uploads and processes a valid XML file", %{conn: conn} do
      upload = %Plug.Upload{
        path: @valid_xml_path,
        filename: "test_file.xml",
        content_type: "application/xml"
      }

      conn = post(conn, ~p"/api/files", %{file: upload})

      response = json_response(conn, 201)
      assert response["message"] == "File successfully uploaded and processed"
      assert response["upload_file_name"] == "test_file.xml"
      assert response["plaintiff"] == "ANGELO ANGELES, an individual,"
      assert response["defendants"] == "HILL-ROM COMPANY, INC., an Indiana ) corporation; and DOES 1 through 100, inclusive,"
    end

    test "returns an error for invalid XML", %{conn: conn} do
      upload = %Plug.Upload{
        path: @invalid_xml_path,
        filename: "invalid_sample.xml"
      }

      conn = post(conn, ~p"/api/files", %{file: upload})

      assert json_response(conn, 422)["error"] =~ "Invalid file type. Please upload an XML file."
    end
  end

  describe "GET /api/files/search" do
    test "searches for files by filename", %{conn: conn} do
      {:ok, _file} = %FileSchema{}
      |> FileSchema.changeset(%{
        upload_file_name: "test_file.xml",
        uploaded_time: DateTime.utc_now() |> DateTime.truncate(:second),
        plaintiff: "John Doe",
        defendants: "Jane Smith"
      })
      |> Repo.insert()
      conn = get(conn, "/api/files/search?filename=test_file")
      assert conn.state == :sent, "Expected the connection state to be :sent, but it was #{inspect(conn.state)}"
      assert conn.status in 200..299, "Expected a successful status code, but got #{inspect(conn.status)}"

      response = response(conn, conn.status)

      case Jason.decode(response) do
        {:ok, decoded_response} ->
          assert is_list(decoded_response["files"]), "Expected 'files' to be a list"
          assert length(decoded_response["files"]) > 0, "Expected at least one file in the response"

          matching_file = Enum.find(decoded_response["files"], fn file ->
            file["upload_file_name"] == "test_file.xml"

          end)

          assert matching_file, "Expected to find a file matching the search criteria"

        {:error, _} ->
          flunk("Failed to decode JSON response: #{inspect(response)}")
      end
    end

    test "returns an empty list when no files match", %{conn: conn} do
      conn = get(conn, "/api/files/search?filename=nonexistent")

      response = json_response(conn, 404)
      assert response["message"] == "No files found matching the search criteria."
    end
  end
end
