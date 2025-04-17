defmodule PhraseInterview.Repo.Migrations.AddTimezonesTable do
  use Ecto.Migration

  def up do
    create table("timezones") do
      add :name, :string

      timestamps()
    end

    create index("timezones", [:name], unique: true)
  end

  def down do
    drop table("timezones")
  end
end
