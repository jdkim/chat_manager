require "test_helper"

# Render-level test for ChatManager::_chat_card — pins the `title` attribute
# on the chat-card link so the browser shows the full chat title on hover
# even when the visible text is truncate(30)-clipped.
class ChatCardPartialTest < ActionView::TestCase
  include Rails.application.routes.url_helpers

  # Small stand-in for the host app's Chat AR model. The partial only needs
  # `uuid` and `title`.
  Ann = Struct.new(:uuid, :title, keyword_init: true)

  test "the chat-card link carries `title=<full title>` so long titles show on hover" do
    ann = Ann.new(uuid: "u-1", title: "A very long chat title that gets truncated to thirty characters in the visible label but should still be fully visible on hover")

    # Match the production call form (string-first): the whole options
    # hash becomes the partial's locals, so `locals:` is delivered as a
    # local variable named `locals` holding the inner hash.
    html = render "chat_manager/chat_card", locals: {
      ann: ann,
      is_active: false,
      card_path: ->(_uuid) { "#" },
      download_csv_path: nil,
      delete_path: nil,
      selectable: false
    }

    # The link element gets a title attribute equal to the full title.
    assert_includes html, %(title="#{ann.title}"), "chat-card link should have a title attribute"
    # And the visible label is the 30-char truncated form (Rails' truncate
    # includes the "..." omission within the 30-char cap).
    assert_includes html, "A very long chat title that..."
  end

  test "the title attribute is empty (but present) when chat.title is blank" do
    ann = Ann.new(uuid: "u-2", title: "")
    # Match the production call form (string-first): the whole options
    # hash becomes the partial's locals, so `locals:` is delivered as a
    # local variable named `locals` holding the inner hash.
    html = render "chat_manager/chat_card", locals: {
      ann: ann,
      is_active: false,
      card_path: ->(_uuid) { "#" },
      download_csv_path: nil,
      delete_path: nil,
      selectable: false
    }
    assert_includes html, %(title=""), "empty title still renders as `title=\"\"` — harmless"
  end
end
