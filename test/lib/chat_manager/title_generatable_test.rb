require "test_helper"

# Tests for the TitleGeneratable concern. Two real bugs we've fixed in the
# past sat on top of this code path: titles like "Undefined Image" came
# from passing raw image-markdown into `summarize_for_title`, and titles
# could be rewritten on re-prompts when the early-exit was bypassed.
# The cases here pin the load-bearing contract:
#
#   * Title-already-set short-circuit — `generate_title` MUST NOT call
#     `summarize_for_title` when `title` is already populated.
#   * Truncation cap of 255 chars (the column limit).
#   * Blank / nil summary → no update.
#   * `summarize_for_title` exceptions are rescued, logged, and never
#     bubble up — title generation is best-effort, not critical-path.
#   * The default `summarize_for_title` raises NotImplementedError so a
#     host model that forgets to implement it fails loud, not silent.
class ChatManager::TitleGeneratableTest < ActiveSupport::TestCase
  # Minimal in-memory stand-in for a host Chat model — provides the
  # `title` attribute and an `update!` setter that the concern expects,
  # plus a swappable `summarize_for_title` so each test controls its
  # return value.
  class FakeChat
    attr_accessor :title, :update_calls, :summarize_stub

    def initialize(title: nil)
      @title = title
      @update_calls = []
    end

    def update!(attrs)
      @update_calls << attrs
      attrs.each { |k, v| public_send("#{k}=", v) }
      true
    end

    include ChatManager::TitleGeneratable

    private

    def summarize_for_title(prompt_text, jwt_token)
      @summarize_stub.call(prompt_text, jwt_token)
    end
  end

  setup do
    @chat = FakeChat.new
  end

  test "skips summarization entirely when the title is already populated" do
    @chat.title = "Existing Title"
    called = false
    @chat.summarize_stub = ->(_p, _t) { called = true; "should not run" }

    @chat.generate_title("any prompt", "jwt")

    assert_equal "Existing Title", @chat.title
    assert_empty @chat.update_calls
    refute called, "summarize_for_title must not run when title is already set"
  end

  test "stores the summary as the title when summarize returns text" do
    @chat.summarize_stub = ->(prompt, jwt) {
      assert_equal "Hello world", prompt
      assert_equal "jwt-tok", jwt
      "Casual greeting"
    }

    @chat.generate_title("Hello world", "jwt-tok")

    assert_equal "Casual greeting", @chat.title
    assert_equal [ { title: "Casual greeting" } ], @chat.update_calls
  end

  test "does NOT update the title when summarize returns blank" do
    @chat.summarize_stub = ->(_p, _t) { "" }
    @chat.generate_title("prompt", "jwt")
    assert_nil @chat.title
    assert_empty @chat.update_calls
  end

  test "does NOT update the title when summarize returns nil" do
    @chat.summarize_stub = ->(_p, _t) { nil }
    @chat.generate_title("prompt", "jwt")
    assert_nil @chat.title
    assert_empty @chat.update_calls
  end

  test "truncates a long summary to 255 characters before persisting" do
    long_summary = "x" * 500
    @chat.summarize_stub = ->(_p, _t) { long_summary }

    @chat.generate_title("prompt", "jwt")

    assert_equal 255, @chat.title.length
    assert @chat.title.end_with?("..."), "expected truncate to add an ellipsis"
  end

  test "swallows exceptions from summarize_for_title and logs them" do
    @chat.summarize_stub = ->(_p, _t) { raise StandardError, "upstream timeout" }
    logger_io = StringIO.new
    original = Rails.logger
    Rails.logger = ActiveSupport::Logger.new(logger_io)

    # Must not raise — title generation is best-effort.
    @chat.generate_title("prompt", "jwt")

    assert_nil @chat.title
    assert_empty @chat.update_calls
    assert_match(/Failed to generate chat title.*upstream timeout/, logger_io.string)
  ensure
    Rails.logger = original
  end

  test "the default summarize_for_title raises NotImplementedError to force host implementation" do
    # A host that forgets to implement #summarize_for_title shouldn't get
    # silent no-ops — it should fail loud at the first call.
    plain_class = Class.new do
      attr_accessor :title
      def initialize; @title = nil end
      def update!(*); end
      include ChatManager::TitleGeneratable
    end

    err = assert_raises(NotImplementedError) do
      plain_class.new.send(:summarize_for_title, "x", "jwt")
    end
    assert_match(/must implement #summarize_for_title/, err.message)
  end

  test "generate_title rescues the NotImplementedError too (best-effort), but the title stays unset" do
    # The concern's begin/rescue catches StandardError specifically, and
    # NotImplementedError is NOT a StandardError — so a host that forgets
    # to override DOES get the exception bubbled up here. Pinning this
    # boundary means a future refactor that swaps the rescue to
    # `rescue Exception` would trip this spec.
    plain_class = Class.new do
      attr_accessor :title
      def initialize; @title = nil end
      def update!(*); end
      include ChatManager::TitleGeneratable
    end

    assert_raises(NotImplementedError) do
      plain_class.new.generate_title("prompt", "jwt")
    end
  end
end
