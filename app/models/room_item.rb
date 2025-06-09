class RoomItem < ApplicationRecord
  belongs_to :room

  validates :name, presence: true
  validates :quantity, numericality: { greater_than: 0 }
end
