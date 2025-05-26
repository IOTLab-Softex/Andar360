class ParticipantsReservation < ApplicationRecord
  belongs_to :participant
  belongs_to :reservation
end
