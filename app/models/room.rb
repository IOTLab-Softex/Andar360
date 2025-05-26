class Room < ApplicationRecord
    has_many :reservations, dependent: :destroy
    belongs_to :device
    has_one_attached :photo
  
    validates :name, :device, :floor, presence: true
end
