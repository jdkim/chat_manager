# ChatManager

A Rails engine for managing LLM chat conversations with CSV export, auto-titling, and ready-to-use UI components.

## Features

- **Chat Management** — Controller concern (`ChatManageable`) for initializing and managing chat arrays with duplicate/nil prevention
- **Automatic Title Generation** — Model concern (`TitleGeneratable`) for generating chat titles from initial prompts
- **CSV Export** — Controller concern (`CsvDownloadable`) for individual and bulk chat CSV downloads
- **UI Components** — Chat list and chat card partials with Stimulus-powered inline title editing
- **Database Migration Generator** — `chat_manager:modeling` generator for creating the chats table
- **Turbo/Turbolinks Safe** — CSV download links work correctly with modern Rails JS frameworks

## Requirements

- Ruby 3.4+
- Rails 8.1+

## Installation

Add this line to your application's Gemfile:

```ruby
gem "chat_manager"
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install chat_manager
```

## Setup

### 1. Run the migration generator

```bash
$ rails generate chat_manager:modeling
$ rails db:migrate
```

This creates the `chat_manager_chats` table with the following columns:

| Column | Type | Description |
|---|---|---|
| `uuid` | string (NOT NULL) | Unique identifier for the chat |
| `title` | string | Chat title (auto-generated or manually set) |
| `llm_uuid` | string | LLM identifier |
| `model` | string | Model name/type |
| `created_at` | datetime | Timestamp |
| `updated_at` | datetime | Timestamp |

### 2. Include concerns in your controller

```ruby
class ChatsController < ApplicationController
  include ChatManager::ChatManageable
  include ChatManager::CsvDownloadable

  def index
    initialize_chat(current_user.chats)
    set_active_chat_uuid(params[:uuid])
  end
end
```

### 3. Include the title generation concern in your model

```ruby
class Chat < ApplicationRecord
  include ChatManager::TitleGeneratable

  # You must implement this method
  def summarize_for_title(prompt_text, jwt_token)
    # Call your LLM API to generate a title from the prompt
    # Return a string (max 255 characters)
  end
end
```

## Usage

### ChatManageable (Controller Concern)

Provides methods for managing chat arrays in your controller:

```ruby
initialize_chat(chats)        # Initialize with a collection of chats
set_active_chat_uuid(uuid)    # Set the active chat UUID
add_chat(chat)                # Add a chat (prevents nil and duplicates)
```

### CsvDownloadable (Controller Concern)

Provides CSV export actions:

```ruby
download_csv      # Download a single chat as CSV
download_all_csv  # Download all user chats as CSV
```

CSV output includes the following columns: `Chat Title`, `Role`, `Message Content`, `Sent At`, `Model`.

### TitleGeneratable (Model Concern)

Generates a chat title from the initial user prompt:

```ruby
chat.generate_title(prompt_text, jwt_token)
```

Delegates to the `summarize_for_title` method which must be implemented by the including model.

### View Helper

Use the `chat_list` helper in your views to render the chat list UI:

```erb
<%= chat_list(
  card_path: ->(chat) { chat_path(chat.uuid) },
  active_uuid: @active_uuid,
  download_csv_path: ->(chat) { download_csv_chat_path(chat.uuid) },
  download_all_csv_path: download_all_csv_chats_path
) %>
```

Parameters:

| Parameter | Required | Description |
|---|---|---|
| `card_path` | Yes | Proc/lambda returning the path for each chat card link |
| `active_uuid` | No | UUID of the currently active chat (for highlighting) |
| `download_csv_path` | No | Proc/lambda returning the CSV download path for each chat |
| `download_all_csv_path` | No | Path for the "Download All Chats CSV" button |

### UI Components

The engine provides two partials:

- **`chat_manager/chat_list`** — Renders the full chat list with optional bulk CSV download button
- **`chat_manager/chat_card`** — Renders an individual chat card with:
  - Title display (truncated to 30 characters)
  - Active state highlighting
  - Inline title editing via Stimulus (`chat-title-edit` controller)
  - Optional per-chat CSV download button

### Stylesheets

The engine includes CSS for the chat interface. Available CSS classes:

- `.chat-stack` — Flex column layout for the chat list
- `.chat-card` — Card styling with hover effects and active state
- `.chat-card-link` — Grid layout for card content
- `.chat-card-title-input` — Inline edit input field
- `.chat-download-all-link` — Bulk download button

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
