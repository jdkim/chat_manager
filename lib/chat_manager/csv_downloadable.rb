# frozen_string_literal: true

require "csv"

module ChatManager
  module CsvDownloadable
    extend ActiveSupport::Concern

    CSV_HEADERS = [ "Chat Title", "Role", "Message Content", "Sent At", "LLM UUID", "Model" ].freeze

    def download_csv
      chat = current_user.chats.includes(messages: :prompt_manager_prompt_execution).find_by!(uuid: params[:id])

      csv_data = generate_csv_for_chats([ chat ])

      filename = "chat_#{chat.title.to_s.parameterize.presence || chat.uuid}_#{Date.today}.csv"
      send_data csv_data, filename: filename, type: "text/csv"
    end

    def download_all_csv
      chats = current_user.chats.includes(messages: :prompt_manager_prompt_execution)

      csv_data = generate_csv_for_chats(chats)

      send_data csv_data, filename: "all_chats_#{Date.today}.csv", type: "text/csv"
    end

    private

    def generate_csv_for_chats(chats)
      CSV.generate do |csv|
        csv << CSV_HEADERS
        chats.each do |chat|
          chat.ordered_messages.each do |msg|
            pe = msg.prompt_manager_prompt_execution
            content = msg.role == "user" ? pe&.prompt : pe&.response
            csv << [ chat.title, msg.role, content, msg.created_at, chat.llm_uuid, chat.model ]
          end
        end
      end
    end
  end
end
