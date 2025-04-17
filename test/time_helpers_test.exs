defmodule PhraseInterview.TimeHelpersTest do
  use ExUnit.Case, async: true

  alias PhraseInterview.TimeHelpers

  describe "format_zone/2" do
    test "returns formatted time and zone abbreviation for valid timezone" do
      datetime = ~U[2025-04-16 13:37:00Z]
      assert {:ok, time, abbrev} = TimeHelpers.format_zone(datetime, "Europe/Berlin")
      assert time =~ ~r/\A\d{2}:\d{2}\z/
      assert abbrev == "CEST" || abbrev == "CET"
    end

    test "returns error for invalid timezone" do
      datetime = ~U[2025-04-16 13:37:00Z]
      assert {:error, reason} = TimeHelpers.format_zone(datetime, "Not/AZone")
      assert reason == "time_zone_not_found"
    end
  end

  describe "parse_time/2" do
    test "parses valid 24h time and returns DateTime with new hour and minute" do
      time = "13:37"
      {:ok, dt} = TimeHelpers.parse_time(time, "Europe/Berlin")
      assert dt.hour == 13
      assert dt.minute == 37
    end

    test "returns error for malformed time string" do
      assert {:error, msg} = TimeHelpers.parse_time("99:88", "Europe/Berlin")
      assert msg =~ "Invalid"
    end

    test "returns error for invalid timezone" do
      assert {:error, msg} = TimeHelpers.parse_time("13:37", "Not/AZone")
      assert msg =~ "Invalid"
    end
  end

  describe "zone_to_city/1" do
    test "returns city name from a full timezone" do
      assert TimeHelpers.zone_to_city("Europe/Paris") == "Paris"
      assert TimeHelpers.zone_to_city("America/New_York") == "New York"
    end
  end

  describe "city_name_to_zone/1" do
    test "returns timezone for known city" do
      assert TimeHelpers.city_name_to_zone("Berlin") in Tzdata.zone_list()
    end

    test "handles spaces and case insensitivity" do
      assert TimeHelpers.city_name_to_zone("buenos aires") =~ "Buenos_Aires"
    end

    test "returns nil for unknown city" do
      assert TimeHelpers.city_name_to_zone("Bielefeld2") == nil
    end
  end
end
