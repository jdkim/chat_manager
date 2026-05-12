module ChatManager
  module Helpers
    def chat_list(card_path,
                  active_uuid: nil,
                  download_csv_path: nil,
                  delete_path: nil,
                  batch_delete_path: nil,
                  batch_download_csv_path: nil)
      render "chat_manager/chat_list", locals: {
        card_path: card_path,
        active_uuid: active_uuid,
        download_csv_path: download_csv_path,
        delete_path: delete_path,
        batch_delete_path: batch_delete_path,
        batch_download_csv_path: batch_download_csv_path
      }
    end
  end
end
