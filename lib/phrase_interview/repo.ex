defmodule PhraseInterview.Repo do
  use Ecto.Repo,
    otp_app: :phrase_interview,
    adapter: Ecto.Adapters.SQLite3
end
