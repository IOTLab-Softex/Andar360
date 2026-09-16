source "https://rubygems.org"

ruby "3.3.11"

gem 'httparty'
gem 'net-http-digest_auth'
gem 'rufus-scheduler'
gem 'rest-client'
gem 'ffi'
gem 'rubyzip', '~> 2.3'
gem 'chunky_png'
gem 'devise'

gem 'delayed_job_active_record'
gem 'daemons' # para rodar o worker em segundo plano se desejar
gem 'inline_svg'
gem "ckeditor"
gem 'roo'
gem 'roo-xls'
gem "webpush", "1.1.0"









# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.0.2"
gem "psych", "= 5.1.2"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use sqlite3 as the database for Active Record
#gem "sqlite3", ">= 2.1"
gem 'pg'
# Use Puma when HTTPS/local SSL is needed.
gem "puma", ">= 5.0", require: false
gem "webrick", platforms: %i[ mingw x64_mingw mswin ]
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"


# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data"


# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy tooling isn't needed for local Windows boot
gem "kamal", require: false, platforms: :mri

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.2"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
end

group :test do
  # Rails 8.0's test runner uses the Minitest 5 API.
  gem "minitest", "~> 5.0"
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
end

gem "mini_magick", "~> 5.4"

#gem 'ruby-vips'


#gem 'net-ping'
