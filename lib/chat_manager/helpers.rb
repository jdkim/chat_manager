module ChatManager
  module Helpers
    def chat_list(card_path, active_uuid: nil, download_csv_path: nil, download_all_csv_path: nil)
      render "chat_manager/chat_list", locals: { card_path: card_path, active_uuid: active_uuid, download_csv_path: download_csv_path, download_all_csv_path: download_all_csv_path }
    end
  end
end
