defmodule PhraseInterviewWeb.TimezoneLiveTest do
  use PhraseInterviewWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  @valid_timezone "Europe/Berlin"
  @invalid_timezone "Doesnt/Exist"

  describe "mount/3" do
    test "renders initial page", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/timezone")
      assert html =~ "Add City Name"
    end
  end

  describe "use_current_time" do
    test "sets selected_time", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/timezone")
      assert render_click(view, :use_current_time) =~ ~r/value="\d+.\d+"/
    end

    test "starts update timer", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/timezone")

      render_click(view, :use_current_time)

      state = :sys.get_state(view.pid)
      assert is_reference(state.socket.assigns[:scheduled_time_update])
    end
  end

  describe "use_custom_time" do
    test "sets a valid time", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/timezone")

      assert render_change(view, :use_custom_time, %{"time" => "12:30"}) =~ "value=\"12:30\""
    end

    test "shows error on invalid time", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/timezone")

      assert render_change(view, :use_custom_time, %{"time" => "foobar"}) =~ ~r/value="\d+.\d+"/
    end

    test "stops update timer", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/timezone")

      render_change(view, :use_custom_time, %{"time" => "12:30"})

      state = :sys.get_state(view.pid)
      assert is_nil(state.socket.assigns[:scheduled_time_update])
    end

    test "all saved zones reflect the new custom time", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/timezone")
      form = element(view, "form[phx-submit=add_city]")
      render_submit(form, %{"name" => @valid_timezone})

      {:ok, now} = DateTime.now(@valid_timezone)
      {:ok, time, _zone} = PhraseInterview.TimeHelpers.format_zone(now, @valid_timezone)

      assert render_change(view, :use_custom_time, %{"time" => time}) =~ ">#{time}</td>"
    end
  end

  describe "add_city" do
    setup do
      # Clean up to prevent duplicate entries
      PhraseInterview.TimezonesQuery.delete(@valid_timezone)
      :ok
    end

    test "adds a valid city", %{conn: conn} do
      {:ok, view, html} = live(conn, "/timezone")
      city = PhraseInterview.TimeHelpers.zone_to_city(@valid_timezone)
      refute html =~ ">#{city}</td>"

      form = element(view, "form[phx-submit=add_city]")
      assert render_submit(form, %{"name" => @valid_timezone}) =~ ">#{city}</td>"
      assert Enum.member?(PhraseInterview.TimezonesQuery.list(), @valid_timezone)
    end

    test "does not add invalid city", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/timezone")
      form = element(view, "form[phx-submit=add_city]")

      assert render_submit(form, %{"name" => @invalid_timezone}) =~ "Add City Name"
    end
  end

  describe "delete_city" do
    setup do
      PhraseInterview.TimezonesQuery.add(@valid_timezone)
      :ok
    end

    test "deletes city from list", %{conn: conn} do
      {:ok, view, html} = live(conn, "/timezone")
      city = PhraseInterview.TimeHelpers.zone_to_city(@valid_timezone)
      assert html =~ ">#{city}</td>"

      refute render_click(view, :delete_city, %{"zone" => @valid_timezone}) =~ ">#{city}</td>"
      refute Enum.member?(PhraseInterview.TimezonesQuery.list(), @valid_timezone)
    end
  end

  describe "locale selection" do
    test "updates locale", %{conn: conn} do
      {:ok, view, html} = live(conn, "/timezone?locale=en")
      assert html =~ "Enter Time"

      assert view
             |> element("a", "Deutsch")
             |> render_click() =~ "Zeit eingeben"
    end
  end
end
