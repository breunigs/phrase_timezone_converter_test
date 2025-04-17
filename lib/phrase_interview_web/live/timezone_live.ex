defmodule PhraseInterviewWeb.TimezoneLive do
  use PhraseInterviewWeb, :live_view
  require Logger

  @fallback_timezone "Europe/Berlin"

  def render(%{selected_time: sel_time, default_timezone: tz} = assigns) do
    display =
      with {:ok, time, _abbrev} <- PhraseInterview.TimeHelpers.format_zone(sel_time, tz) do
        time
      end

    assigns =
      assign(assigns, %{
        display: display,
        saved_zones: saved_zones(sel_time)
      })

    ~H"""
    <div class="max-w-2xl mx-auto p-6 space-y-8">
      <form>
        <label for="time">
          <h1 class="block text-xl font-semibold text-gray-800 mb-2">
            <%= gettext "Enter Time", locale: @locale %>
          </h1>
        </label>
        <input
          type="time"
          id="time"
          name="time"
          value={@display}
          class="block input w-32 mb-1"
          phx-change="use_custom_time"
        />
        <a href="#" phx-click="use_current_time" class="text-blue-600 hover:underline">
          <%= gettext "Use Current Time", locale: @locale %>
        </a>
      </form>

      <h1 class="block text-xl font-semibold text-gray-800 mb-2"><%= gettext "Your Timezones", locale: @locale %></h1>
      <%= if @saved_zones != [] do %>
        <table class="w-full table-auto border-collapse">
          <thead class="text-left">
            <tr>
              <th class="py-1"><%= gettext "City", locale: @locale %></th>
              <th class="py-1"><%= gettext "Time", locale: @locale %></th>
              <th class="py-1"><%= gettext "TZ", locale: @locale %></th>
              <th class="py-1"></th>
            </tr>
          </thead>
          <%= for {zone, city, time, abbrev} <- @saved_zones do %>
            <tr class="hover:bg-gray-100">
              <td class="py-1">{city}</td>
              <td class="py-1">{time}</td>
              <td class="py-1">{abbrev}</td>
              <td class="py-1">
                <a
                  href="#"
                  phx-click="delete_city"
                  title={gettext "Remove timezone", locale: @locale}
                  phx-value-zone={zone}
                >
                  <.icon name="hero-trash-solid" />
                </a>
              </td>
            </tr>
          <% end %>
        </table>
      <% end %>

      <.form for={@add_city_form} phx-submit="add_city">
        <label for="name" class="block text-lg font-medium mb-1">
          <%= gettext "Add City Name", locale: @locale %>
        </label>
        <div class="flex items-end gap-4 items-start">
          <div class="flex-1">
            <.input
              list="city_names"
              type="text"
              id="name"
              name="name"
              value={@add_city_form[:name].value}
              autocomplete="off"
              placeholder={gettext "Type City Name here…", locale: @locale}
              field={@add_city_form[:name]}
            />
          </div>
          <button
            type="submit"
            class="mt-[2px] bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition"
          >
            <%= gettext "Add", locale: @locale %>
          </button>
        </div>
        <datalist id="city_names">
          <%= for city <- @city_names do %>
            <option>{city}</option>
          <% end %>
        </datalist>
      </.form>

      <h1 class="block text-xl font-semibold text-gray-800 mb-2">
        <%= gettext "Select Language", locale: @locale %>
      </h1>
      <.link patch={~p"/timezone?locale=de"} class="text-blue-600 hover:underline">Deutsch</.link>
      |
      <.link patch={~p"/timezone?locale=en"} class="text-blue-600 hover:underline">English</.link>
    </div>
    """
  end

  def mount(params, _session, socket) do
    socket =
      socket
      |> set_locale(params)
      |> set_default_timezone()
      |> assign(%{
        city_names: city_names(),
        add_city_form: blank_city_form(),
        page_title: gettext("Timezone Converter")
      })
      |> use_current_time()

    {:ok, socket}
  end

  defp set_locale(socket, params) do
    gettext = Application.get_env(:phrase_interview, PhraseInterviewWeb.Gettext)

    locale =
      if params["locale"] in gettext[:locales],
        do: params["locale"],
        else: gettext[:default_locale]

    Gettext.put_locale(PhraseInterviewWeb.Gettext, locale)
    assign(socket, :locale, locale)
  end

  def handle_params(params, _url, socket) do
    {:noreply, set_locale(socket, params)}
  end

  def handle_event("add_city", params, socket) do
    parsed = PhraseInterview.TimeHelpers.city_name_to_zone(params["name"])

    form =
      with {:ok, _} <- PhraseInterview.TimezonesQuery.add(parsed || params["name"]) do
        blank_city_form()
      else
        {:error, changeset} -> to_form(changeset)
      end

    socket =
      assign(socket, %{
        add_city_form: form,
        # remove added city from autocomplete
        city_names: city_names()
      })

    {:noreply, socket}
  end

  def handle_event("delete_city", params, socket) do
    with {:error, changeset} <- PhraseInterview.TimezonesQuery.delete(params["zone"]) do
      Logger.warning(
        "failed to delete city from params #{inspect(params)}: #{inspect(changeset)}"
      )
    end

    socket = assign(socket, :city_names, city_names())

    {:noreply, socket}
  end

  def handle_event("use_current_time", _params, socket) do
    {:noreply, use_current_time(socket)}
  end

  def handle_event("use_custom_time", %{"time" => time}, socket) do
    socket =
      with {:ok, parsed} <-
             PhraseInterview.TimeHelpers.parse_time(time, socket.assigns.default_timezone) do
        socket
        |> cancel_time_update()
        |> assign(:selected_time, parsed)
      else
        {:error, reason} ->
          Logger.debug("invalid user time: #{reason}")
          socket
      end

    {:noreply, socket}
  end

  def handle_info(:use_current_time, socket) do
    {:noreply, use_current_time(socket)}
  end

  defp use_current_time(socket) do
    # TODO: read from user DB
    {:ok, dt} = DateTime.now(socket.assigns.default_timezone)

    socket
    |> assign(:selected_time, dt)
    |> schedule_time_update()
  end

  defp schedule_time_update(socket) do
    socket = cancel_time_update(socket)

    %{second: ss, microsecond: {microsec, precision}} = Time.utc_now()
    next_minute_in_ms = ceil(1000 * (60 - ss) + (10 ** precision - microsec) / 1000)
    Logger.debug("next minute in #{next_minute_in_ms} ms")

    timer_ref = Process.send_after(self(), :use_current_time, next_minute_in_ms)
    assign(socket, :scheduled_time_update, timer_ref)
  end

  defp cancel_time_update(socket) do
    if socket.assigns[:scheduled_time_update],
      do: Process.cancel_timer(socket.assigns[:scheduled_time_update])

    assign(socket, :scheduled_time_update, nil)
  end

  defp blank_city_form() do
    Ecto.Changeset.change(%PhraseInterview.Timezones{}) |> to_form()
  end

  defp city_names() do
    # Cities and Timezones are not a perfect match. E.g. US/Pacific and
    # Canada/Pacific are not cities, yet common timezones in use.
    (Tzdata.zone_list() -- PhraseInterview.TimezonesQuery.list())
    |> Enum.group_by(&PhraseInterview.TimeHelpers.zone_to_city/1)
    |> Enum.reduce([], fn {group, tz}, acc ->
      if length(tz) == 1, do: [group | acc], else: tz ++ acc
    end)
    |> Enum.map(&String.replace(&1, "_", " "))
    |> Enum.sort()
  end

  @spec saved_zones(binary()) :: [{binary(), binary(), binary(), binary()}]
  defp saved_zones(datetime) do
    PhraseInterview.TimezonesQuery.list()
    |> Enum.map(fn zone ->
      with {:ok, time, abbrev} <- PhraseInterview.TimeHelpers.format_zone(datetime, zone) do
        {zone, PhraseInterview.TimeHelpers.zone_to_city(zone), time, abbrev}
      else
        {:error, reason} ->
          Logger.debug("failed to format time zone=#{zone} from DB: #{reason}")
          {zone, PhraseInterview.TimeHelpers.zone_to_city(zone), "ERR", "ERR"}
      end
    end)
    |> Enum.sort_by(&elem(&1, 1))
  end

  defp set_default_timezone(socket) do
    # TODO: We don't know the visiting user's time zone. There's a bunch of
    # options:
    # - send the accurate time zone via JavaScript on connect
    # - guess from IP (needs GeoIP Database and config changes to extract
    #   headers/remote_ip from transport)
    # - store it in a user table (and add a signup flow)
    # I scoped this out for this exercise.
    assign(socket, :default_timezone, @fallback_timezone)
  end
end
