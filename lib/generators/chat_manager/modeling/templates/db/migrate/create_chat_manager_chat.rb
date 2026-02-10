class CreateChatManagerChat < ActiveRecord::Migration[8.1]
  def change
    create_table :chat_manager_chats do |t|
      t.string :uuid, null: false
      t.string :title
      t.string :llm_uuid
      t.string :model

      t.timestamps
    end
  end
end
