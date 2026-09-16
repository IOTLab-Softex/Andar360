require_relative "../config/boot"
require "rackup"

Rackup::Server.start(
  config: File.expand_path("../config.ru", __dir__),
  server: "webrick", environment: "production", Host: "127.0.0.1", Port: 3001
)
