class Device < ApplicationRecord
  belongs_to :room, optional: true
  has_many :rooms

  validates :name, :ip, :user, :password, presence: true
end
