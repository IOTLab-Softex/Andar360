require_relative "../config/environment"

Delayed::Worker.new.start
