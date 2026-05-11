# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`chat_manager` is a mountable Rails engine (isolated namespace `ChatManager`) that provides reusable concerns, view helpers, partials, and a migration generator for LLM chat management in a host Rails app. It is packaged and released as a gem on rubygems.org.

- Ruby: 3.4.9 (see `.ruby-version`). CI runs 3.4.7; floor is 3.4.
- Rails: `>= 8.1.2` (engine depends on `rails/all` and ActiveRecord migrations target `[8.1]`).
- Tests run against `test/dummy`, an in-repo host app.

## Common Commands

All commands run from the repo root.

```bash
bin/rails test                                 # Run the full test suite (boots test/dummy)
bin/rails test test/path/to/file_test.rb       # Run a single file
bin/rails test test/path/to/file_test.rb:42    # Run a single test at line 42
bin/rubocop                                    # Lint (uses rubocop-rails-omakase)
bin/rubocop -a                                 # Auto-fix safe offenses
bin/rails db:migrate                           # Migrate the dummy app DB
bin/rails generate chat_manager:modeling       # Exercise the migration generator (against dummy app)
bundle exec rake build                         # Build the gem
bundle exec rake release                       # Release the gem (bumps via version.rb)
```

CI (`.github/workflows/ci.yml`) runs `bin/rubocop -f github` and `bin/rails test` on Ruby 3.4.7.

## Architecture

The engine exposes three capability surfaces; each is opt-in by the host app.

### Auto-included on boot (`lib/chat_manager/engine.rb`)
- `ChatManager::Helpers` is mixed into all `ActionView` via `on_load(:action_view)` — the `chat_list` view helper is available app-wide without an explicit include.
- `ChatManager::ChatManageable` is mixed into all `ActionController` via `on_load(:action_controller)` — so `initialize_chat`, `set_active_chat_uuid`, `add_chat` are available in every controller. The README's "include ChatManager::ChatManageable" is therefore documentation, not a requirement.
- Asset paths under `app/assets/stylesheets` and `app/javascript` are appended, and `chat_manager/chat.css` + `chat_manager/application.css` are added to `assets.precompile`.

### Opt-in concerns (host controller/model includes them)
- `ChatManager::CsvDownloadable` (controller) — `download_csv` / `download_all_csv` actions. Depends on the host providing: `current_user.chats`, `chats.includes(messages: :prompt_navigator_prompt_execution)`, `Chat#ordered_messages`, and messages with `role` plus a `prompt_navigator_prompt_execution` association exposing `prompt` and `response`. CSV columns are fixed: `Chat Title, Role, Message Content, Sent At, Model`.
- `ChatManager::TitleGeneratable` (model) — `generate_title(prompt_text, jwt_token)` is a no-op if `title` is present; otherwise delegates to `summarize_for_title`, which the including model **must** implement (raises `NotImplementedError` otherwise). Result is truncated to 255 chars; all `StandardError` is swallowed and logged.

### View layer coupling to the host app
The `_chat_card.html.erb` partial calls `main_app.update_title_chat_path(ann.uuid)` directly. The host app must define an `update_title_chat` route (PATCH) and a matching controller action — the gem does not provide it. The card is driven by a Stimulus controller named `chat-title-edit` (referenced via `data-controller`), which must also be registered on the host side.

When editing the chat list/card partials, preserve these contracts:
- `chat_list(card_path, active_uuid:, download_csv_path:, download_all_csv_path:, delete_path:)` — `card_path`, `download_csv_path`, `delete_path` are procs/lambdas that each take a UUID and return a path. `download_all_csv_path` is a plain path string.
- Download links set `data: { turbo: false }` — required for `send_data` to work under Turbo/Turbolinks. Do not remove this.
- Only chats with `title.present?` are rendered; untitled chats are filtered out in the partial.

### Schema
`lib/generators/chat_manager/modeling/` generates a single migration creating `chat_manager_chats` with `uuid (NOT NULL), title, llm_uuid, model, timestamps`. There is no model class shipped in `app/models/chat_manager/` for `Chat` — the host app defines the `Chat` model (likely in its own namespace) and includes `TitleGeneratable`.

## Testing Notes

- `test/test_helper.rb` boots `test/dummy` and wires both the dummy app's and the engine's `db/migrate` into `ActiveRecord::Migrator.migrations_paths`. The generator templates live under `lib/generators/.../templates/db/migrate/` and are **not** auto-migrated in tests — tests that need the `chat_manager_chats` table must either run the generator into `test/dummy` or add a fixture migration.
- Fixtures path is `test/fixtures`.
- The default test is a smoke test asserting `ChatManager::VERSION` is defined.

## Release Flow

Version lives in `lib/chat_manager/version.rb`. The repo follows Keep a Changelog + SemVer. Steps:

1. Bump `version.rb` and add a `CHANGELOG.md` entry.
2. Commit to `main` (pattern: `chore: release vX.Y.Z`).
3. Tag the release commit: `git tag vX.Y.Z <sha> && git push origin vX.Y.Z`.

Pushing a `v*` tag triggers `.github/workflows/gem_release.yml`, which publishes to rubygems.org via trusted publishing (OIDC — no API key needed; the workflow declares `id-token: write`). The workflow also supports `workflow_dispatch`. Merging to `main` alone does **not** publish — the tag push is the trigger.

Do not hand-edit `Gemfile.lock` for a version bump — `bundle install` after editing `version.rb` will update it.
