defmodule PhraseInterview.Timezones do
  use Ecto.Schema

  schema "timezones" do
    field :name, :string
    timestamps()
  end

  def changeset(timezone, params \\ %{}) do
    timezone
    |> Ecto.Changeset.cast(params, [:name])
    |> Ecto.Changeset.validate_required([:name])
    |> Ecto.Changeset.validate_inclusion(:name, Tzdata.zone_list())
  end
end
