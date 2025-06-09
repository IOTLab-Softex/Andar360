class Room < ApplicationRecord
    has_many :reservations, dependent: :destroy
    belongs_to :device
    has_many :room_items, dependent: :destroy
    accepts_nested_attributes_for :room_items, allow_destroy: true
    has_one_attached :photo
  
    validates :name, :device, :floor, presence: true
end
