Rails.application.routes.draw do
  mount ChatManager::Engine => "/chat_manager"

  # Stubs required for rendering the ChatManager::_chat_card partial in
  # tests — the partial references `main_app.update_title_chat_path(uuid)`
  # and the caller supplies its own procs for card_path / delete_path.
  resources :chats, only: [] do
    member do
      patch :update_title
    end
  end
end
