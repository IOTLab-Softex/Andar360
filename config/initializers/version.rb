# config/initializers/version.rb
APP_VERSION = File.read(Rails.root.join("VERSION")).strip.freeze
