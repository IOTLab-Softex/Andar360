# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"
Rails.application.config.assets.paths << Rails.root.join("app/assets/images/icones")

Rails.application.config.assets.paths << Rails.root.join("app", "assets", "icones")
Rails.application.config.assets.paths << Rails.root.join("app", "assets", "icones", "free", "solid")
Rails.application.config.assets.paths << Rails.root.join("app", "assets", "icones", "icons_custom", "solid")

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path
