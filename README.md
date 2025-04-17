# PhraseInterview

## Setup

```bash
# Install Elixir if not already done so, e.g.
asdf install

# Install sqlite if not already done so, e.g.
apt install sqlite3

git clone https://github.com/breunigs/phrase_timezone_converter_test
cd phrase_timezone_converter_test/

mix setup
mix test
mix phx.server
```

You can then browse the (unsecured) timezone converter at
[localhost:4000](http://localhost:4000).

## Development

### Security

The application may only be run in trusted networks, where users won't
misbehave. There is no separation by user, i.e. changes are global. Intended
usage is a wall clock for at home usage.

### Code Layout

The main view is located at `lib/phrase_interview_web/live/timezone_live.ex`. It
contains the core business logic. The HTML template is also currently inlined
there.

The database stores saved timezones by their name in Tzdata. The schema for
`timezones` table is in `lib/phrase_interview/timezones.ex`, access helpers in
`lib/phrase_interview/timezones_query.ex`. Display of city names is directly
derived from the time zone's human readable/long name.

### Update Logic

To avoid needlessly pushing updates through the websocket, the next update is
scheduled by calculating the time left to the next minute. When the user
manually selects a time, this scheduler needs to be stopped to avoid overwriting
the selected time. This makes the scheduling logic a bit more complicated, but
simplifies the usage for rendering because a only single `DateTime` in
`assigns.selected_time` needs to be considered.

## Notes

- The initial time zone is hardcoded for this exercise. In a proper application,
  it should be guessed from IP, sent via JS from the browser, or stored in the
  user's database.
- I left the init boilerplate as is, as opposed to adding a commit where I
  remove all unneeded bits. (time saver for me)
- I did not setup dialyzer (dialyxir). With Elixir adding more type checking
  directly, its effort/value tradeoff doesn't seem worth it any longer.
- There is an opportunity to extract the HTML template into its own heex file.
  Similarly, `city_names/0` or `saved_zones/1` might be moved outside of
  `TimezoneLive`. I opted not to do additional refactoring on the exercise to
  save time, and because extracting pieces elsewhere at this small level doesn't
  strike me as obviously better.
- It's the first time I used Tailwind CSS. How did I do? I didn't check this on
  mobile browsers.
- The `time` input might use AM/PM style, but the table will always use 24h
  style. Clearly a future improvement possibility.
- I skipped ARIA to save time for this exercise.
- TzData also contains timezone without city names like "Canada/Pacific". The
  implementation currently ignores that. For a real product, the UI requirements
  would need to be evolved, because it seems sensible to keep such timezones
  available instead of only allowing "real cities". Similarly, "Bejing" as an
  example from the exercise specification is not an actual timezone in TzData
  upstream, for which many bug reports can be found. It's intentional, but maybe
  that decision shouldn't be reflected in our time zone converter.
- sqlite was chosen because it's least painful for tiny applications and
  installation
- I'm aware of the `set_locale` package, but it caused infinite redirects, for
  which I could not identify the issue in a short timebox. Hence the ad-hoc
  implementation.
