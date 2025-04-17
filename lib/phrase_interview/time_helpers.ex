defmodule PhraseInterview.TimeHelpers do
  @type timezone() :: binary()

  @doc """
  Returns given time in the give timezone. It also returns the zone's
  abbreviation or UTC offset.
  """
  @spec format_zone(DateTime.t(), timezone()) ::
          {:ok, time :: binary(), zone_abbrev :: binary()} | {:error, reason :: binary()}
  def format_zone(datetime, zone) do
    with {:ok, shifted} <- DateTime.shift_zone(datetime, zone) do
      {:ok, Calendar.strftime(shifted, "%H:%M"), shifted.zone_abbr}
    else
      {:error, reason} -> {:error, to_string(reason)}
    end
  end

  @doc """
  Takes a colon separated timestamp formatted in 24h hours string (e.g. "13:37")
  and a valid timezone.
  """
  @spec parse_time(binary(), timezone()) :: {:ok, DateTime.t()} | {:error, reason :: binary()}
  def parse_time(time, zone) do
    with [hh, mm] <- String.split(time, ":", parts: 2),
         {h_int, ""} when h_int >= 0 and h_int <= 23 <- Integer.parse(hh),
         {m_int, ""} when m_int >= 0 and m_int <= 59 <- Integer.parse(mm),
         {:ok, dt} <- DateTime.now(zone) do
      {:ok, %{dt | hour: h_int, minute: m_int}}
    else
      parse_state ->
        {:error, "Invalid \"#{time}\" or \"#{zone}\", last parse step: #{inspect(parse_state)}"}
    end
  end

  @doc """
  Tries to extract city name from a time zone name. Since only some common time
  zones contain city names, this function will often produce incorrect results
  (e.g. for "US/Pacific" timezone).
  """
  @spec zone_to_city(timezone()) :: binary()
  def zone_to_city(timezone) do
    timezone |> String.split("/") |> List.last() |> String.replace("_", " ")
  end

  @doc """
  Tries to match the given city name to a known/valid timezone.
  """
  @spec city_name_to_zone(binary()) :: timezone() | nil
  def city_name_to_zone(name) do
    name = name |> String.downcase() |> String.replace(" ", "_")

    Tzdata.zone_list()
    |> Enum.find(fn tz ->
      tz |> String.downcase() |> String.ends_with?(name)
    end)
  end
end
