# test/xml_parser/schemas/file_test.exs
defmodule XmlParser.Schemas.FileTest do
  use XmlParser.DataCase
  alias XmlParser.Schemas.File, as: FileSchema

  @valid_attrs %{
    upload_file_name: "test/fixtures/test_file.xml",
    uploaded_time: DateTime.utc_now(),
    plaintiff: "John Doe",
    defendants: "Jane Smith"
  }

  describe "changeset/2" do
    test "creates a valid changeset with proper attributes" do
      changeset = FileSchema.changeset(%FileSchema{}, @valid_attrs)
      assert changeset.valid?
    end

    test "requires upload_file_name" do
      changeset = FileSchema.changeset(%FileSchema{}, Map.delete(@valid_attrs, :upload_file_name))
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).upload_file_name
    end

    test "requires uploaded_time" do
      changeset = FileSchema.changeset(%FileSchema{}, Map.delete(@valid_attrs, :uploaded_time))
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).uploaded_time
    end

    test "validates plaintiff is a string" do
      attrs = Map.put(@valid_attrs, :plaintiff, 123)
      changeset = FileSchema.changeset(%FileSchema{}, attrs)
      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).plaintiff
    end

    test "validates defendants is a list of strings" do
      attrs = Map.put(@valid_attrs, :defendants, ["Valid", 123])
      changeset = FileSchema.changeset(%FileSchema{}, attrs)
      refute changeset.valid?
      assert "is invalid" in errors_on(changeset).defendants
    end
  end
end
