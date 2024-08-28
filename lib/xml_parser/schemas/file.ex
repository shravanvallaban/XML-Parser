defmodule XmlParser.Schemas.File do
  use Ecto.Schema
  import Ecto.Changeset
  @derive {Jason.Encoder, only: [:id, :upload_file_name, :uploaded_time, :plaintiff, :defendants, :inserted_at, :updated_at]}

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "files" do
    field :upload_file_name, :string
    field :uploaded_time, :utc_datetime
    field :plaintiff, :string
    field :defendants, :string

    timestamps()
  end

  def changeset(file, attrs) do
    file
    |> cast(attrs, [:upload_file_name, :uploaded_time, :plaintiff, :defendants])
    |> validate_required([:upload_file_name, :uploaded_time, :plaintiff, :defendants])
  end
end
