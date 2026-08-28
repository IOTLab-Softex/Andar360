$ErrorActionPreference = "Stop"

$rubyRoot = "C:\Ruby33-x64"
$env:RI_FORCE_PATH_FOR_DLL = "1"
$env:RUBYLIB = Join-Path $PSScriptRoot "ruby_overrides"
$env:PATH = @(
  "$rubyRoot\bin",
  "$rubyRoot\lib\ruby\3.3.0\x64-mingw-ucrt",
  "$rubyRoot\msys64\ucrt64\bin",
  "$rubyRoot\msys64\usr\bin",
  $env:PATH
) -join ";"

$env:RAILS_ENV = "production"
$env:RACK_ENV = "production"

if (-not $env:SECRET_KEY_BASE) {
  $env:SECRET_KEY_BASE = ruby -e "require 'securerandom'; puts SecureRandom.hex(64)"
}

Remove-Item (Join-Path $PSScriptRoot "tmp\pids\server.pid") -ErrorAction SilentlyContinue

bundle exec rackup config.ru -s webrick -E production -o 127.0.0.1 -p 3000
