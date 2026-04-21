# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

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
