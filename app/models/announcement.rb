class Announcement < ApplicationRecord
  belongs_to :created_by, class_name: "User", optional: true
  has_many   :announcement_views, dependent: :destroy
  has_and_belongs_to_many :grupo_empresas,
                          join_table: :announcement_grupo_empresas
  has_one_attached :image
  has_one_attached :video

  scope :active,    -> { where(active: true).order(position: :asc, created_at: :asc) }
  scope :in_period, -> {
    now = Time.current
    where("(starts_at IS NULL OR starts_at <= ?) AND (ends_at IS NULL OR ends_at >= ?)", now, now)
  }

  def self.expire_passed!
    where(active: true)
      .where.not(ends_at: nil)
      .where("ends_at < ?", Time.current)
      .update_all(active: false)
  end
  scope :visible_to, ->(user) {
    gid = user.participant&.grupo_empresa_id&.to_i || 0
    where(
      "announcements.id NOT IN (SELECT announcement_id FROM announcement_grupo_empresas)" \
      " OR announcements.id IN (SELECT announcement_id FROM announcement_grupo_empresas WHERE grupo_empresa_id = ?)",
      gid
    )
  }

  def viewed_by?(user)
    announcement_views.exists?(user: user)
  end

  def for_all_companies?
    grupo_empresas.empty?
  end
end
