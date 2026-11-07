# Home Dashboard Extension Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a "Home Dashboard" screen combining a digital clock and device battery status on device `TRMNL` (id 1), by exposing device battery data to the Liquid rendering context and authoring one custom `static` Extension.

**Architecture:** Move the existing voltage→percentage conversion from the web UI's `Views::Parts::Device` down onto the `Structs::Device` read model, add a `liquid_attributes` method to it (mirroring `Structs::DeviceSensor#liquid_attributes`), and thread a new `"device"` key through `Aspects::Extensions::Contextualizer`. The dashboard itself is then a normal Extension authored through the existing web UI — no new UI code — using the officially documented TRMNL Framework `layout`, `title`, `label`, and `progress-bar` classes.

**Tech Stack:** Ruby, Hanami 3, ROM/Sequel structs, RSpec, Liquid templating, TRMNL Framework CSS (loaded from `https://trmnl.com/css/latest/plugins.css`, not vendored in this repo).

**Reference:** `docs/superpowers/specs/2026-08-20-home-dashboard-design.md` (crit-approved design).

**Deviation from the design doc, noted here for the record:** the design lists adding a `charging?` predicate to `Structs::Device`. The `charging` column is already a plain boolean reader on the struct and is sufficient for both the Liquid template (`{% if device.charging %}`) and the web UI's existing `battery_measurement_label` (`return "Charging" if charging`) — a `charging?` alias adds no behavior, so it's dropped here (YAGNI). Everything else in the design is implemented as written.

---

### Task 1: `Structs::Device` — battery percentage and Liquid attributes

**Files:**
- Modify: `app/structs/device.rb`
- Test: `spec/app/structs/device_spec.rb`

- [ ] **Step 1: Write the failing tests**

Add to `spec/app/structs/device_spec.rb` (after the existing `#screen_attributes` block, before the final `end`):

```ruby
  describe "#battery_percentage" do
    it "answers battery_charge when it is positive" do
      device = Factory.structs[:device, battery_charge: 42.0, battery_voltage: 3.0]
      expect(device.battery_percentage).to eq(42.0)
    end

    it "answers a voltage-derived percentage when battery_charge is zero" do
      device = Factory.structs[:device, battery_charge: 0, battery_voltage: 3.0]
      expect(device.battery_percentage).to eq(70)
    end

    it "answers zero when battery_voltage is zero" do
      device = Factory.structs[:device, battery_charge: 0, battery_voltage: 0]
      expect(device.battery_percentage).to eq(0)
    end
  end

  describe "#liquid_attributes" do
    it "answers attributes" do
      device = Factory.structs[
        :device,
        battery_charge: 0,
        battery_voltage: 3.0,
        charging: false
      ]

      expect(device.liquid_attributes).to eq(
        "device_id" => device.id,
        "battery_charge" => 0,
        "battery_voltage" => 3.0,
        "battery_percentage" => 70,
        "charging" => false
      )
    end
  end
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `bin/rspec spec/app/structs/device_spec.rb -e "#battery_percentage" -e "#liquid_attributes"`
Expected: FAIL with `NoMethodError: undefined method 'battery_percentage'` (and similarly for `liquid_attributes`).

- [ ] **Step 3: Implement `battery_percentage` and `liquid_attributes`**

Replace the full contents of `app/structs/device.rb` with:

```ruby
# frozen_string_literal: true

require "core"
require "refinements/hash"

module Terminus
  module Structs
    # The device struct.
    class Device < DB::Struct
      using Refinements::Hash

      def asleep? at = Time.now, type: Sequel::SQLTime
        return false unless sleep_start_at && sleep_stop_at

        now = type.create at.hour, at.min, at.sec

        if sleep_stop_at < sleep_start_at
          now >= sleep_start_at || now <= sleep_stop_at
        else
          (sleep_start_at..sleep_stop_at).cover? now
        end
      end

      def battery_percentage
        battery_charge.positive? ? battery_charge : battery_voltage_to_percent
      end

      def display_attributes
        {
          image_url_timeout: image_timeout,
          maximum_compatibility: display_compatibility,
          refresh_rate:,
          temperature_profile: display_profile,
          touchbar_mode: touch_bar,
          update_firmware: firmware_update
        }
      end

      def liquid_attributes
        {device_id: id, battery_charge:, battery_voltage:, battery_percentage:, charging:}
          .stringify_keys!
      end

      def slug
        return Core::EMPTY_STRING unless mac_address

        mac_address.tr ":", Core::EMPTY_STRING
      end

      def screen_label(prefix) = "#{prefix} #{id}"

      def screen_name(kind) = "#{kind}_#{id}"

      def screen_attributes kind
        {
          device_id: id,
          model_id:,
          label: screen_label(kind.capitalize),
          name: screen_name(kind),
          kind:
        }
      end

      private

      def battery_voltage_to_percent
        case battery_voltage
          when 0 then 0
          when ..0.45 then 10
          when ..0.9 then 20
          when ..1.35 then 30
          when ..1.8 then 40
          when ..2.25 then 50
          when ..2.7 then 60
          when ..3.15 then 70
          when ..3.6 then 80
          when ..4.05 then 90
          else 100
        end
      end
    end
  end
end
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `bin/rspec spec/app/structs/device_spec.rb`
Expected: PASS (all examples, including the pre-existing ones).

- [ ] **Step 5: Commit**

```bash
git add app/structs/device.rb spec/app/structs/device_spec.rb
git commit -m "Add battery_percentage and liquid_attributes to Structs::Device"
```

---

### Task 2: `Views::Parts::Device` — delegate battery percentage to the struct

**Files:**
- Modify: `app/views/parts/device.rb`
- Test: run existing specs for this Part (see step 2)

- [ ] **Step 1: Confirm existing coverage before changing**

Run: `bin/rspec spec/app/views/parts/device_spec.rb 2>&1 || echo "no dedicated part spec"`

If a dedicated spec file exists, note it — it must still pass after this change. If not, the feature specs under `spec/features/devices_spec.rb` (which render the device page and its battery label) are the safety net; note that filename instead.

- [ ] **Step 2: Remove the now-duplicated logic**

In `app/views/parts/device.rb`, delete the `#battery_percentage` method and the private `#battery_voltage_to_percent` method entirely (they now live on `Structs::Device`, and `Hanami::View::Part#method_missing` delegates undefined calls to the wrapped struct — confirmed at `hanami-view` gem's `lib/hanami/view/part.rb:213-215`). The file becomes:

```ruby
# frozen_string_literal: true

require "hanami/view"
require "refinements/struct"

module Terminus
  module Views
    module Parts
      # The device presenter.
      class Device < Hanami::View::Part
        include Deps["aspects.screens.fetcher", "aspects.screens.placeholder"]

        using Refinements::Struct

        def battery_measurement_label
          return "Charging" if charging

          "Battery (#{helpers.format_number battery_percentage, precision: 0}%)"
        end

        def formatted_display_profile = display_profile.capitalize

        def formatted_touch_bar = touch_bar.capitalize

        def wake_description = String(wake_reason).empty? ? "Unknown." : wake_reason

        def wifi_measurement_label
          band = wifi_band
          band.zero? ? "WiFi (#{wifi_percentage}%)" : "#{band} GHz (#{wifi_percentage}%)"
        end

        def wifi_percentage
          case wifi_signal
            when 0 then 0
            when ..-91 then 10
            when -90..-81 then 20
            when -80..-71 then 30
            when -70..-67 then 40
            when -66..-62 then 50
            when -61..-57 then 60
            when -56..-52 then 70
            when -51..-47 then 80
            when -46..-40 then 90
            else 100
          end
        end

        def dimensions = "#{width}x#{height}"

        def current_screen
          fetcher.call(value).either -> screen { screen },
                                     proc { placeholder.with id: id }
        end
      end
    end
  end
end
```

- [ ] **Step 3: Run the safety-net spec to verify no regression**

Run: `bin/rspec spec/features/devices_spec.rb`
Expected: PASS. If it fails on the battery label, check the failure message — it means `method_missing` delegation didn't reach `battery_percentage`; re-verify Task 1 was committed and `bin/rspec spec/app/structs/device_spec.rb` still passes on its own first.

- [ ] **Step 4: Commit**

```bash
git add app/views/parts/device.rb
git commit -m "Delegate device battery percentage to Structs::Device"
```

---

### Task 3: `Contextualizer` — expose device battery data to Liquid

**Files:**
- Modify: `app/aspects/extensions/contextualizer.rb`
- Test: `spec/app/aspects/extensions/contextualizer_spec.rb`

- [ ] **Step 1: Write the failing test changes**

Replace the full contents of `spec/app/aspects/extensions/contextualizer_spec.rb` with:

```ruby
# frozen_string_literal: true

require "hanami_helper"

RSpec.describe Terminus::Aspects::Extensions::Contextualizer, :db do
  subject(:contextualizer) { described_class.new }

  using Refinements::Hash

  describe "#call" do
    let :extension do
      Factory.structs[
        :extension,
        label: "Test",
        fields: [{"keyname" => "one", "default" => 1}],
        data: {"label" => "Test"}
      ]
    end

    let :model do
      Factory[
        :model,
        name: "test",
        css: {
          "classes" => {"size" => "screen--lg"},
          "variables" => [%w[--screen-w 1040px], %w[--screen-h 780px]]
        }
      ]
    end

    let(:device) { Factory[:device, model_id: model.id] }
    let(:sensor) { Factory[:device_sensor, device_id: device.id] }

    it "answers all attributes" do
      sensor

      expect(contextualizer.call(extension, model_id: model.id, device_id: device.id)).to eq(
        "extension" => {
          "label" => "Test",
          "data" => {"label" => "Test"},
          "fields" => [{"keyname" => "one", "default" => 1}],
          "values" => {"one" => 1},
          "css_classes" => "screen screen--test screen--1bit screen--landscape screen--lg"
        },
        "screen_variables" => "--screen-w: 1040px;\n--screen-h: 780px;",
        "sensors" => [
          {
            "device_id" => device.id,
            "kind" => "temperature",
            "make" => "ACME",
            "model" => "Test",
            "unit" => "celcius",
            "value" => 20.1,
            "source" => "device",
            "created_at" => Time.new(2025, 1, 1).utc
          }
        ],
        "device" => {
          "device_id" => device.id,
          "battery_charge" => device.battery_charge,
          "battery_voltage" => device.battery_voltage,
          "battery_percentage" => device.battery_percentage,
          "charging" => device.charging
        }
      )
    end

    it "answers attributes without fields, values, model, sensors, and device" do
      extension = Factory.structs[:extension, label: "Test"]

      expect(contextualizer.call(extension)).to eq(
        "extension" => {
          "label" => "Test",
          "css_classes" => nil,
          "data" => {},
          "fields" => [],
          "values" => {}
        },
        "screen_variables" => nil,
        "sensors" => [],
        "device" => nil
      )
    end
  end
end
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `bin/rspec spec/app/aspects/extensions/contextualizer_spec.rb`
Expected: FAIL — the actual hash won't have a `"device"` key at all (`expected: ... "device" => {...}, actual: {..., "sensors" => []}` with a diff showing the missing key).

- [ ] **Step 3: Implement the `device` key**

Replace the full contents of `app/aspects/extensions/contextualizer.rb` with:

```ruby
# frozen_string_literal: true

require "refinements/hash"

module Terminus
  module Aspects
    module Extensions
      # Assembles the Liquid context for rendering screens.
      class Contextualizer
        include Deps[
          "aspects.models.finder",
          device_repository: "repositories.device",
          sensor_repository: "repositories.device_sensor"
        ]

        using Refinements::Hash

        def call extension, model_id: nil, device_id: nil
          model = finder.call(model_id:, device_id:).value_or(nil)

          {
            "extension" => extension.liquid_attributes.merge!(
              "css_classes" => (model.css_classes.join " " if model)
            ),
            "screen_variables" => (model.css_variables.join "\n" if model),
            "sensors" => load_sensors(device_id),
            "device" => load_device(device_id)
          }
        end

        private

        def load_sensors(device_id) = sensor_repository.where(device_id:).map(&:liquid_attributes)

        def load_device(device_id) = device_repository.find(device_id)&.liquid_attributes
      end
    end
  end
end
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `bin/rspec spec/app/aspects/extensions/contextualizer_spec.rb`
Expected: PASS (both examples).

- [ ] **Step 5: Run the full extensions aspect suite for regressions**

Run: `bin/rspec spec/app/aspects/extensions/`
Expected: PASS. `Renderer`/`ScreenUpserter` specs call the real `Contextualizer` collaborator, so this catches any caller that builds its own expected-context hash and would now be missing the `"device"` key.

- [ ] **Step 6: Commit**

```bash
git add app/aspects/extensions/contextualizer.rb spec/app/aspects/extensions/contextualizer_spec.rb
git commit -m "Expose device battery data to the Liquid rendering context"
```

---

### Task 4: Full quality gate

**Files:** none (verification only)

- [ ] **Step 1: Run the full suite**

Run: `bin/rake`
Expected: PASS — `git_lint`, `reek`, `rubocop`, `hadolint`, and the full RSpec suite all green. Fix any failures before moving on; this is the same gate the project runs before every push (per `CLAUDE.md`).

---

### Task 5: Author the "Home Dashboard" extension (manual, via the running app)

This task has no new application code — it's content authored through the existing Extensions UI, exactly as any Terminus user would do it. Run `overmind start --port-step 10 --procfile Procfile.dev --can-die assets,migrate` first if the app isn't already running, and log in at `http://localhost:2300`.

- [ ] **Step 1: Inspect the public "Digital Clock" recipe for reference**

Visit `http://localhost:2300/extensions/gallery`, search "Digital Clock", and open the recipe at `trmnl.com/recipes/190574`'s preview. This is a reference/inspection step per the design doc's rationale (don't hand-roll something that already exists) — note whether its Liquid markup is directly reusable. Do not import-and-keep it as a standalone extension; the concrete template below is what actually ships, built from TRMNL Framework's officially documented `layout`, `title`, `label`, and `progress-bar` components (verified at `trmnl.com/framework/docs/3.2/layout` and `.../progress`) rather than an unknown third party's exact markup, since that markup can't be known ahead of importing it and may not even be Liquid (some community clock recipes use client-side JS/SVG instead).

- [ ] **Step 2: Create the extension**

Go to `http://localhost:2300/extensions/new`. Fill in:

- **Label:** `Home Dashboard`
- **Name:** `home_dashboard`
- **Kind:** `Static` (radio button — no exchange/webhook needed, neither widget pulls external data)
- **Static Body:** `{}`

- [ ] **Step 3: Paste the template**

In the **Template and Input** field, paste:

```liquid
<div class="layout layout--row layout--center">
  <div class="layout layout--col layout--center stretch-x">
    <span class="label">{{ "now" | date: "%A, %B %-d" }}</span>
    <span class="title title--xxlarge">{{ "now" | date: "%H:%M" }}</span>
  </div>

  <div class="layout layout--col layout--center stretch-x">
    <span class="label">{% if device.charging %}Charging{% else %}Battery{% endif %}</span>

    <div class="progress-bar progress-bar--large">
      <div class="content">
        <span class="value value--xxsmall">{{ device.battery_percentage | round }}%</span>
      </div>
      <div class="track">
        <div class="fill" style="width: {{ device.battery_percentage | round }}%"></div>
      </div>
    </div>
  </div>
</div>
```

- [ ] **Step 4: Set the Build Matrix**

In the **Build Matrix** section, choose the **Devices** radio (not Models), and select `TRMNL` (device id 1) in the Devices multi-select.

- [ ] **Step 5: Set the schedule**

In the **Schedule** section: **Interval** `5`, **Unit** `minute`. Leave Start blank (starts immediately).

- [ ] **Step 6: Save and build**

Click **Save**. On the extension's show page, click **Build** to force an immediate render, then check `http://localhost:2300/screens` for the new "Home Dashboard" screen and confirm it shows the current time and today's date on the left, and a percentage + filled bar matching the device's current battery reading on the right (compare against `http://localhost:2300/devices/1`'s battery label — they should match, since both now read `Structs::Device#battery_percentage`).

- [ ] **Step 7: Add it to a playlist**

Go to `http://localhost:2300/playlists`, open (or create) the playlist assigned to device `TRMNL`, and add the "Home Dashboard" screen to it so the device actually displays it on its next poll.

---

### Self-review

**Spec coverage:** backend change (Task 1 + 3), web UI de-duplication (Task 2), extension/template/schedule (Task 5), quality gate (Task 4) — all design sections covered. No feature spec was planned in the design and none is added here, matching the design's "Testing" section.

**Placeholder scan:** no TBD/TODO; every code step has complete, runnable code; the one inherently-manual task (Task 5) has exact field values and exact Liquid/CSS classes, verified against TRMNL Framework's own docs rather than invented.

**Type/name consistency:** `battery_percentage`, `liquid_attributes`, `device_repository`, and the `"device"` context key are spelled identically across Tasks 1, 2, and 3.
