# app/models/access_log.rb
class AccessLog < ApplicationRecord
  belongs_to :participant
  belongs_to :reservation

  validates :participant_id, :reservation_id, :accessed_at, presence: true
end
