require "test_helper"

# Tests for the CSV-generation logic inside the CsvDownloadable controller
# concern. The public action methods (download_csv / download_selected_csv)
# are Rails plumbing — params + send_data — so we test the private
# `generate_csv_for_chats` directly. That's where the real format
# decisions live:
#
#   * Header row order is fixed (matches CSV_HEADERS constant).
#   * For `role == "user"`, the row's Message Content comes from
#     prompt_execution.prompt; for any other role, from .response.
#     This boundary is the place a regression would either leak the
#     model's response into the user row or drop assistant content.
#   * Multiple chats interleave: header once at the top, then all
#     messages from all chats in order.
#   * A Message with no associated prompt_execution surfaces a blank
#     content cell instead of raising.
class ChatManager::CsvDownloadableTest < ActiveSupport::TestCase
  # Minimal controller-like host. The concern's public actions touch
  # Rails internals (params, send_data) so we don't exercise them; we
  # only call the private CSV builder.
  class FakeHost
    include ChatManager::CsvDownloadable
    public :generate_csv_for_chats
  end

  # Faked domain objects — match the duck-typed interface the concern
  # reads (title, model, ordered_messages on a chat; role, created_at,
  # prompt_navigator_prompt_execution on a message; prompt and response
  # on a PE).
  Chat = Struct.new(:title, :model, :ordered_messages, keyword_init: true)
  Msg  = Struct.new(:role, :created_at, :prompt_navigator_prompt_execution, keyword_init: true)
  PE   = Struct.new(:prompt, :response, keyword_init: true)

  setup do
    @host = FakeHost.new
  end

  test "headers are emitted in the CSV_HEADERS order on row 0" do
    rows = parse(@host.generate_csv_for_chats([]))
    assert_equal ChatManager::CsvDownloadable::CSV_HEADERS, rows[0]
  end

  test "an empty chat list produces a CSV with only the header row" do
    rows = parse(@host.generate_csv_for_chats([]))
    assert_equal 1, rows.size
  end

  test "user-role rows pull content from prompt_execution.prompt" do
    chat = make_chat(title: "Greetings", model: "gpt-5", messages: [
      msg("user", "Hello", "Hi back")
    ])

    rows = parse(@host.generate_csv_for_chats([ chat ]))
    assert_equal "user", rows[1][1]
    assert_equal "Hello", rows[1][2]
  end

  test "non-user-role rows pull content from prompt_execution.response" do
    chat = make_chat(title: "T", model: "gpt-5", messages: [
      msg("assistant", "shouldn't appear", "Hi back")
    ])

    rows = parse(@host.generate_csv_for_chats([ chat ]))
    assert_equal "assistant", rows[1][1]
    assert_equal "Hi back", rows[1][2]
  end

  test "row carries the chat's title and model on every line (denormalized for CSV consumers)" do
    chat = make_chat(title: "Casual chat", model: "claude-opus-4-7", messages: [
      msg("user", "P", "R"),
      msg("assistant", "P", "R")
    ])

    rows = parse(@host.generate_csv_for_chats([ chat ]))
    body = rows[1..]
    assert_equal [ "Casual chat", "Casual chat" ], body.map { |r| r[0] }
    assert_equal [ "claude-opus-4-7", "claude-opus-4-7" ], body.map { |r| r[4] }
  end

  test "a message with no prompt_execution yields a blank content cell instead of raising" do
    chat = make_chat(title: "T", model: "m", messages: [
      Msg.new(role: "user", created_at: Time.utc(2026, 5, 30), prompt_navigator_prompt_execution: nil)
    ])

    rows = parse(@host.generate_csv_for_chats([ chat ]))
    # CSV.parse round-trips an empty field as nil (default behavior); the
    # important thing is that the missing prompt_execution doesn't raise.
    assert rows[1][2].blank?
  end

  test "interleaves rows from multiple chats with a single header at the top" do
    chat_a = make_chat(title: "A", model: "m", messages: [ msg("user", "pA", "rA") ])
    chat_b = make_chat(title: "B", model: "m", messages: [
      msg("user", "pB1", "rB1"),
      msg("assistant", "pB1", "rB1")
    ])

    rows = parse(@host.generate_csv_for_chats([ chat_a, chat_b ]))
    # Header + 1 (chat_a) + 2 (chat_b) = 4 rows total.
    assert_equal 4, rows.size
    titles = rows[1..].map { |r| r[0] }
    assert_equal %w[A B B], titles
  end

  test "the timestamp column is the message's created_at, not the chat's" do
    msg_time = Time.utc(2026, 1, 15, 12, 30, 0)
    chat = make_chat(title: "T", model: "m", messages: [
      Msg.new(role: "user", created_at: msg_time,
              prompt_navigator_prompt_execution: PE.new(prompt: "P", response: "R"))
    ])

    rows = parse(@host.generate_csv_for_chats([ chat ]))
    assert_includes rows[1][3], "2026-01-15"
  end

  private

  def parse(csv_string)
    CSV.parse(csv_string)
  end

  def make_chat(title:, model:, messages:)
    Chat.new(title: title, model: model, ordered_messages: messages)
  end

  def msg(role, prompt, response)
    Msg.new(role: role, created_at: Time.utc(2026, 1, 1),
            prompt_navigator_prompt_execution: PE.new(prompt: prompt, response: response))
  end
end
