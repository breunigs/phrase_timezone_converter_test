defmodule PhraseInterview.TimezonesQuery do
  require Ecto.Query

  @spec list() :: [binary()]
  def list() do
    Ecto.Query.from(PhraseInterview.Timezones, select: [:name])
    |> PhraseInterview.Repo.all()
    |> Enum.map(fn entry -> entry.name end)
  end

  @spec add(binary()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def add(name) do
    %PhraseInterview.Timezones{}
    |> PhraseInterview.Timezones.changeset(%{name: name})
    |> PhraseInterview.Repo.insert(on_conflict: :nothing)
  end

  def delete(name) do
    entry = PhraseInterview.Repo.get_by(PhraseInterview.Timezones, name: name)

    if entry do
      PhraseInterview.Repo.delete(entry, allow_stale: true)
    else
      {:ok, nil}
    end
  end
end
