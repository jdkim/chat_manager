# frozen_string_literal: true

module ChatManager
  module TitleGeneratable
    extend ActiveSupport::Concern

    # Generate a title for the chat by summarizing the user's prompt.
    # Delegates the actual summarization to `summarize_for_title`,
    # which must be implemented by the including model.
    def generate_title(prompt_text, jwt_token)
      return if title.present?

      summary = summarize_for_title(prompt_text, jwt_token)
      update!(title: summary.truncate(255)) if summary.present?
    rescue StandardError => e
      Rails.logger.error "Failed to generate chat title: #{e.class} - #{e.message}"
    end

    private

    # Override this method in your model to provide the actual summarization logic.
    # Should return a short title string.
    def summarize_for_title(_prompt_text, _jwt_token)
      raise NotImplementedError, "#{self.class} must implement #summarize_for_title"
    end
  end
end
