# Home Dashboard Extension — Design (draft, backend section)

## Goal

A single custom "Home Dashboard" screen combining battery status and a digital
clock, built as one Extension (kind: `static`) attached to the local device
`TRMNL` (id 1). Clock shows 24-hour time + date. Battery data must be exposed
to the Liquid template context to make this possible.

## Backend change

Battery data isn't in the Liquid context today. `Contextualizer#call`
(`app/aspects/extensions/contextualizer.rb:14-24`) builds context from
`extension`, `screen_variables`, and `sensors` only — no device battery data,
even though `device_id` already flows through.

Changes:

- **`app/structs/device.rb`**: add `battery_percentage` and `charging?`,
  moving the voltage→percent conversion logic that currently lives only in
  `app/views/parts/device.rb:21-22,61-72` (the web UI's private
  `battery_voltage_to_percent`), so both the web UI and Liquid rendering
  share one implementation instead of duplicating it.
- **`app/structs/device.rb`**: add `liquid_attributes`, following the
  existing pattern in `app/structs/device_sensor.rb:9`
  (`{device_id:, make:, ...}.stringify_keys!`) — returns
  `{device_id:, battery_charge:, battery_voltage:, battery_percentage:, charging:}`.
- **`app/aspects/extensions/contextualizer.rb`**: add a `device_repository`
  dep and add `"device" => device.liquid_attributes` to the context when
  `device_id` is present.
- **`app/views/parts/device.rb`**: `battery_percentage` and the "Charging"
  label delegate to the struct instead of reimplementing the voltage→percent
  conversion.

## Extension: "Home Dashboard"

Rather than hand-rolling clock rendering from scratch, we reuse an existing
public recipe for the clock piece and only build the battery piece custom
(battery is internal device data with no public-recipe fit):

1. **Import the public "Digital Clock" recipe** (`trmnl.com/recipes/190574`)
   via the existing Gallery import flow (`app/actions/extensions/gallery/index.rb`,
   `app/aspects/extensions/importers/remote/creator.rb`). This gives a vetted
   Liquid template with 24-hour/date formatting already implemented — no need
   to write clock-rendering logic from scratch.
2. **Create a new Extension "Home Dashboard"** (kind: `static`, per
   `app/aspects/extensions/renderers/static.rb` — no exchange/webhook needed
   since neither widget pulls external data), attached to device `TRMNL`
   (id 1).
3. **Template**: two-column layout (`layout layout--col`, per the
   `doc/extensions.adoc` walkthrough convention) —
   - Left column: the clock markup adapted from the imported recipe's
     template, configured for 24-hour time + date.
   - Right column: a new battery section using
     `{{ device.battery_percentage }}` and `{{ device.charging }}` from the
     context added in the backend change above.
4. After porting the clock markup into the dashboard template, delete the
   standalone imported "Digital Clock" extension so there isn't a duplicate,
   unused screen left behind.

## Schedule

Rebuild every 5 minutes. The clock only updates when the extension rebuilds
(Terminus renders server-side into a static image — it's not a live tick on
the device), so 5 minutes balances freshness against render load, consistent
with TRMNL's own battery-life rationale for not treating the device as a
live clock (see `help.trmnl.com` — "TRMNL is (not) a clock").

## Error handling

`battery_voltage`/`battery_charge` are `NOT NULL DEFAULT 0` columns
(`config/db/structure.sql:296,308`), matching the existing web UI's
assumption (`app/templates/devices/_measurements.html.erb`) — no null-guard
needed in the template; a fresh device simply shows 0% until firmware
reports a real reading, same as today's device page.

## Testing

- Extend the existing `spec/app/structs/device_spec.rb` with examples for
  `Device#battery_percentage` / `Device#charging?` / `Device#liquid_attributes`.
- Update `spec/app/aspects/extensions/contextualizer_spec.rb` to assert the
  `"device"` key is present when `device_id` is given, and absent when it's
  not.
- No new feature spec planned — the Home Dashboard extension itself is
  authored through the existing UI, not new application code.
