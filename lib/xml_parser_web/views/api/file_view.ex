defmodule XmlParserWeb.Api.FileView do
  def render("index.json", %{data: files}) do
    %{
      "data" => Enum.map(files, &file_json/1)
    }
  end

  def render("show.json", %{data: file}) do
    %{
      "data" => file_json(file)
    }
  end

  def render("error.json", %{error: message}) do
    %{
      "errors" => [
        %{
          "status" => "422",
          "title" => "Unprocessable Entity",
          "detail" => message
        }
      ]
    }
  end

  def render("error.json", %{error: message, details: details}) do
    %{
      "errors" => [
        %{
          "status" => "422",
          "title" => "Unprocessable Entity",
          "detail" => message,
          "meta" => %{
            "details" => details
          }
        }
      ]
    }
  end

  defp file_json(file) do
    %{
      "type" => "file",
      "id" => to_string(file.id),
      "attributes" => %{
        "upload_file_name" => file.upload_file_name,
        "uploaded_time" => file.uploaded_time,
        "plaintiff" => file.plaintiff,
        "defendants" => file.defendants
      }
    }
  end
end
