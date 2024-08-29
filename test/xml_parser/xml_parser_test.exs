# test/xml_parser/xml_parser_test.exs
defmodule XmlParser.XmlParserTest do
  use ExUnit.Case
  alias XmlParser.XmlParser

  @valid_xml "test/fixtures/test_file.xml"

  setup do
    xml_content = File.read!(@valid_xml)
    {:ok, xml_content: xml_content}
  end

  describe "parse/1" do
    test "successfully parses valid XML", %{xml_content: xml_content} do
      result = XmlParser.parse(xml_content)

      assert is_map(result)
      assert is_binary(result.plaintiffs)
      assert is_binary(result.defendants)
    end

    test "returns error for invalid XML" do
      invalid_xml = "This is not valid XML"
      result = XmlParser.parse(invalid_xml)

      assert result == {:error, "Failed to parse XML"}
    end

    test "handles empty string" do
      result = XmlParser.parse("")

      assert result == {:error, "Input cannot be empty"}
    end

    test "handles nil input" do
      result = XmlParser.parse(nil)

      assert result == {:error, "Input cannot be nil"}
    end
  end
end
