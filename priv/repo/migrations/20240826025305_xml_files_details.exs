defmodule XmlParser.Repo.Migrations.XmlFilesDetails do
  use Ecto.Migration

  def change do
    create table(:files, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :upload_file_name, :string, null: false
      add :uploaded_time, :utc_datetime, null: false
      add :plaintiff, :string, null: false
      add :defendants, :string, null: false
      add :case_number, :string
      add :court_name, :string

      timestamps()
    end

    create index(:files, [:upload_file_name])
    create index(:files, [:uploaded_time])
  end

end
