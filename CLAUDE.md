# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Terminus is the flagship open-source BYOS (Build Your Own Server) implementation for [TRMNL](https://trmnl.com) e-paper devices — a Ruby/[Hanami 3](https://hanakai.org/hanami) web server (scaffolded with Hanamismith) that manages devices on a private network. It serves both an htmx-driven web UI and a JSON API that TRMNL firmware polls to fetch the next screen image to display.

## Commands

Setup and run:

```bash
bin/setup                       # Idempotent bootstrap (deps, db, assets); re-run any time
bin/upgrade                     # Upgrade an existing checkout
# Dev server (Puma web + esbuild asset watch + Sidekiq worker, via Overmind + Procfile.dev)
overmind start --port-step 10 --procfile Procfile.dev --can-die assets,migrate
```

App serves at http://localhost:2300 (and https://localhost:2443). Register the first user to get full access.

Tests and quality:

```bash
bin/rake                        # Default task: full quality suite + specs (run before pushing)
bin/rspec                       # RSpec only (all specs)
bin/rspec spec/app/foo_spec.rb          # Single file
bin/rspec spec/app/foo_spec.rb:42       # Single example by line
bin/rake quality                # git_lint + reek + rubocop + hadolint (no specs)
bin/rubocop                     # Lint/format only
bin/console                     # IRB with the app booted (see DI access below)
```

`LOG_LEVEL=debug` (env var or prefixed on the launch command) raises verbosity.

## Architecture

### Dependency injection is the backbone

Hanami auto-registers every class under `app/` (and each slice) into the app container, keyed by its path. This is how components find each other — there is almost no manual wiring.

- `app/repositories/device.rb` → `"repositories.device"`
- `app/aspects/screens/rotator.rb` → `"aspects.screens.rotator"`

Classes pull collaborators with `include Deps[...]`, which defines reader methods:

```ruby
include Deps[
  :settings,
  "aspects.screens.rotator",
  firmware_repository: "repositories.firmware"  # aliased reader
]
```

In `bin/console`, resolve anything with `Hanami.app["repositories.device"]`.

### Aspects = domain service objects

`app/aspects/` holds the real business logic as small, single-responsibility, composable service objects (this is the layer to read first when working on behavior). They compose via `Deps` and communicate results with **dry-monads** `Result` (`Success`/`Failure`) and the `pipeable` gem. The heaviest subtree is `aspects/screens/` — the render pipeline that turns a device's assigned content into an image (mold builder → liquid render → Ferrum headless-Chrome screenshot → ImageMagick greyscale/color conversion), plus `rotator` (pick next screen) and `gaffer` (render an error screen on failure).

### Request layers (see `config/routes.rb`)

Three parallel action namespaces under `app/actions/`, all resolved by DI key:

- **`api.*`** — JSON endpoints mounted under `/api` that devices/firmware call. `Api::Display::Show` (`/api/display`) is the hot path: it authenticates by device API key (overriding the default `authorize`), rotates to the next screen, and returns the image URL payload.
- **UI actions** (e.g. `devices.*`, `screens.*`, `playlists.*`) — top-level htmx/HTML routes rendered via `app/views/` + `app/templates/*.html.erb`.
- **`bulk.*`** — bulk-mutation endpoints under `/bulk`.

`app/action.rb` is the base action: it runs a `before :authorize` hook backed by **Rodauth** (see the `authentication` slice). Actions that must skip auth override `authorize` to a no-op.

### Persistence: ROM + Sequel (not ActiveRecord)

Postgres via **rom-sql**. Three coordinated files per table, all in `app/`:

- `relations/<name>.rb` — low-level dataset / associations
- `repositories/<name>.rb` — query + command API used by the app
- `structs/<name>.rb` — read model returned from repositories

The DB schema is a checked-in structure dump at `config/db/structure.sql` (not per-migration schema.rb).

### Slices

Only two, in `slices/`: `authentication` (Rodauth: login/register/password/remember, its own assets and layout) and `health` (`/up`). The main app lives in `app/`, not a slice.

### Background work

Sidekiq (`app/jobs/`, base at `app/jobs/base.rb`) with sidekiq-scheduler (`config/sidekiq_scheduler.yml`). The `synchronizers/` and `batches/` jobs sync device/extension state. Web UI mounted at `/sidekiq`.

### Frontend

Pure CSS (no framework) in `app/assets/css`, bundled with esbuild via hanami-assets. Interactivity is htmx + Alpine.js; CodeMirror provides the Liquid/JSON editors for extensions and screen templates.

## Conventions

- Content (HTML/CSS from console, API, or UI) is sanitized through `Terminus::Sanitizer` (RELAXED profile). Stripped elements are usually this, not a bug.
- Errors returned to clients use RFC 9457 problem details via the `petail` gem and the `:problem_details` action format registered in `config/app.rb`.
- Follow the existing dry-monads `Result` + `pipeable` style for new service logic rather than raising/returning nils.
- Firmware compatibility is a hard contract (Unbrickable Pledge): the latest Terminus supports the latest firmware — check `README.adoc` before touching firmware/display payload shapes.
- Deeper topic docs live in `doc/*.adoc` (api, devices, extensions, jobs, configuration, docker, kubernetes, render, raspberry_pi).

## Agent skills

### Issue tracker

Issues and specs are local markdown files under `.scratch/<feature>/`. See `docs/agents/issue-tracker.md`.

### Triage labels

Default five-role vocabulary (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`), recorded as a `Status:` line in each issue file. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: root `GLOSSARY.md` plus `docs/adr/`. See `docs/agents/domain.md`.
