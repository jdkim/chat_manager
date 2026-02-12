# frozen_string_literal: true

module ChatManager
  module ChatManageable
    extend ActiveSupport::Concern

    def initialize_chat(chats)
      @chats = chats.to_a
    end

    def set_active_chat_uuid(uuid)
      @active_chat_uuid = uuid
    end

    def push_to_chat(chat)
      @chats << chat
    end
  end
end
