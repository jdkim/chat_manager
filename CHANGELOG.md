# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [1.2.1] - 2026-07-02

### Added

- Chat-card link now carries a `title` attribute holding the full chat title, so long titles (which the sidebar truncates to 30 chars) are visible via the browser's native tooltip on hover.

## [1.2.0] - 2026-06-04

### Added

- Gmail-style multi-select on the chat list — checkbox per card, a kebab menu (delete selected, export selected) on the list toolbar, and a "select all visible" affordance. Selection state lives in a Stimulus controller; the host still owns the destroy / export routes.

### Changed

- Chat-list toolbar is now sticky and visually covers the host sidebar's top padding so chats scroll under it cleanly.

### Tested

- `ChatManager::CsvDownloadable#generate_csv_for_chats` role routing + interleaving of user / assistant rows.
- `ChatManager::TitleGeneratable` short-circuit when `title` is already set, 255-char truncation, and rescue behavior on `StandardError`.

## [1.1.1] - 2026-05-11

### Fixed

- `ChatManager::CsvDownloadable` referenced the old `prompt_manager_prompt_execution` association name, raising `ActiveRecord::AssociationNotFoundError` when host apps had migrated to `prompt_navigator`. The concern (and README/CLAUDE.md docs) now use `prompt_navigator_prompt_execution`.

## [1.1.0] - 2026-04-22

### Added

- Optional `delete_path:` keyword argument to the `chat_list` helper. When provided, each chat card renders a delete button (trash icon) next to the download button. The host app still owns the destroy route and action; the gem only renders the button when a path is supplied.
- CSS styles for `.chat-card-delete` and `.chat-card-delete-form` matching the existing icon-button visual language (red hover for destructive intent).

### Changed

- Revert Ruby version to 3.4.9 (from 4.0.1). README requirement updated to "Ruby 3.4+".

## [1.0.0] - 2026-03-25

### Changed

- Stable release — no functional changes from 0.2.0

## [0.2.0] - 2026-03-14

### Changed

- Bump Ruby version to 4.0.1
- Update README with detailed features and setup guide
- Improve README guidance for Ruby 4.0+

## [0.1.0] - 2026-02-26

### Added

- Chat management module (`ChatManageable`) for controller integration with duplicate and nil prevention
- Automatic chat title generation from initial prompts (`TitleGeneratable`)
- CSV export for individual and bulk chat downloads (`CsvDownloadable`)
- Chat list and chat card UI components with Stimulus-powered inline title editing
- View helper (`chat_list`) for rendering chat lists with customizable paths
- Database migration generator (`chat_manager:modeling`)
- CSS styling for chat interface with active state highlighting and hover effects
- Turbolinks/Turbo safety on CSV download links
- Rails 8.1+ support with `csv` gem dependency for Ruby 3.4+ compatibility
