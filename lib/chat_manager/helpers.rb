module ChatManager
  module Helpers
    def chat_list(card_path, active_uuid: nil)
      render "chat_manager/chat_list", locals: { card_path: card_path, active_uuid: active_uuid }
    end
  end
end
