class UserPresence < ApplicationRecord
  belongs_to :user

  validates :presence_on, presence: true
  validates :user_id, uniqueness: { scope: :presence_on }
end
