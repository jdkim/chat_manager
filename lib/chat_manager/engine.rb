module ChatManager
  class Engine < ::Rails::Engine
    isolate_namespace ChatManager

    initializer "chat_manager.helpers" do
      ActiveSupport.on_load(:action_view) do
        include ChatManager::Helpers
      end
    end

    initializer "chat_manager.controllers" do
      ActiveSupport.on_load(:action_controller) do
        include ChatManager::ChatManageable
      end
    end

    # Configure asset paths for the engine
    # This ensures that JavaScript and CSS files are properly loaded
    initializer "chat_manager.assets", before: "sprockets.environment" do |app|
      # Add asset paths
      app.config.assets.paths << root.join("app/assets/stylesheets").to_s
      app.config.assets.paths << root.join("app/javascript").to_s

      # Precompile assets
      if app.config.respond_to?(:assets)
        app.config.assets.precompile += %w[
          chat_manager/chat.css
          chat_manager/application.css
        ]
      end
    end
  end
end
