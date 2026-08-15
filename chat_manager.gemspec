require_relative "lib/chat_manager/version"

Gem::Specification.new do |spec|
  spec.name        = "chat_manager"
  spec.version     = ChatManager::VERSION
  spec.authors     = [ "dhq_boiler" ]
  spec.email       = [ "dhq_boiler@live.jp" ]
  spec.homepage    = "https://github.com/jdkim/chat_manager"
  spec.summary     = "A Rails engine for managing LLM chat conversations with CSV export and auto-titling."
  spec.description = "ChatManager is a Rails engine that provides chat management, automatic title generation from initial prompts, and CSV export for individual or bulk chat downloads. It includes UI components with Stimulus-powered inline title editing and a database migration generator."
  spec.license     = "Apache-2.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/jdkim/chat_manager"
  spec.metadata["changelog_uri"] = "https://github.com/jdkim/chat_manager/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "LICENSE", "Rakefile", "README.md", "CHANGELOG.md"]
  end

  spec.add_dependency "rails", ">= 8.1.2"
  spec.add_dependency "csv"
end
