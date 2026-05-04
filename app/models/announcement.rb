class Announcement < ApplicationRecord
  belongs_to :created_by, class_name: "User", optional: true
  has_many   :announcement_views, dependent: :destroy
  has_one_attached :image

  scope :active, -> { where(active: true).order(created_at: :desc) }

  def viewed_by?(user)
    announcement_views.exists?(user: user)
  end
end
