class Release < ApplicationRecord
  has_many :feedbacks
  scope :opened, -> { where(released_at: nil) }

  VERSION_FILE = Rails.root.join("VERSION")

  # Leitura
  def self.file_version
    File.exist?(VERSION_FILE) ? File.read(VERSION_FILE).strip : "0.0.1"
  end

  # Escrita
  def self.update_file_version(new_version)
    File.write(VERSION_FILE, new_version)
  end

  def self.current
    opened.first || create!(
      version: file_version,
      stage: "alpha",
      released_at: nil
    )
  end
end
