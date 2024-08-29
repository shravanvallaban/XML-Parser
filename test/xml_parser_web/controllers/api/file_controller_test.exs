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
      assert response["data"]["attributes"]["upload_file_name"] == "test_file.xml"
      assert response["data"]["attributes"]["plaintiff"] == "ANGELO ANGELES, an individual,"
      assert response["data"]["attributes"]["defendants"] == "HILL-ROM COMPANY, INC., an Indiana ) corporation; and DOES 1 through 100, inclusive,"
    end

    test "returns an error for invalid XML", %{conn: conn} do
      upload = %Plug.Upload{
        path: @invalid_xml_path,
        filename: "invalid_sample.xml",
        content_type: "application/xml"
      }

      conn = post(conn, ~p"/api/files", %{file: upload})

      response = json_response(conn, 422)
      assert hd(response["errors"])["detail"] == "Invalid file format. Please upload a valid XML file."
    end
  end

  describe "GET /api/files" do
    test "searches for files by filename", %{conn: conn} do
      {:ok, _file} = %FileSchema{}
      |> FileSchema.changeset(%{
        upload_file_name: "test_file.xml",
        uploaded_time: DateTime.utc_now() |> DateTime.truncate(:second),
        plaintiff: "ANGELO ANGELES, an individual,",
        defendants: "HILL-ROM COMPANY, INC., an Indiana ) corporation; and DOES 1 through 100, inclusive,"
      })
      |> Repo.insert()

      conn = get(conn, ~p"/api/files?filename=test_file")

      response = json_response(conn, 200)
      assert is_list(response["data"]), "Expected 'data' to be a list"
      assert length(response["data"]) > 0, "Expected at least one file in the response"

      matching_file = Enum.find(response["data"], fn file ->
        file["attributes"]["upload_file_name"] == "test_file.xml"
      end)

      assert matching_file, "Expected to find a file matching the search criteria"
    end

    test "returns an empty list when no files match", %{conn: conn} do
      conn = get(conn, ~p"/api/files/search?filename=nonexistent")

      response = json_response(conn, 404)
      assert response["errors"]["detail"] == "Not Found"
    end
  end
end
