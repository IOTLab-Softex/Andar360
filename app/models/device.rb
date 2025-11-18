class Device < ApplicationRecord
  belongs_to :room, optional: true


  validates :name, :ip, :user, :password, presence: true
end
