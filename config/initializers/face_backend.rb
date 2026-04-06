require Rails.root.join("lib", "face_backend", "service")
require Rails.root.join("lib", "face_backend", "client")

if defined?(Rails::Server)
  Thread.new do
    begin
      FaceBackend::Service.ensure_started!
    rescue StandardError => e
      Rails.logger.error("Face backend startup failed: #{e.message}")
    end
  end
end
