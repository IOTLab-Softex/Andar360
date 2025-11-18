class RoomItem < ApplicationRecord
  belongs_to :room, optional: true, inverse_of: :room_items
  has_one_attached :icon
  attr_accessor :catalog_item_id

  validates :name, presence: true
  validates :quantity, numericality: { greater_than: 0 }

  # 🔴 Ícone obrigatório para itens de catálogo (room_id nil)
  validate :catalog_icon_required, if: :catalog_item?

  # 🔎 Tipo do ícone, só quando anexado
  validate :icon_type_ok

  before_validation :hydrate_from_catalog, if: -> { catalog_item_id.present? }

  scope :catalog, -> { where(room_id: nil).order(:name) }
  scope :by_room, ->(room_id) { where(room_id:) }

  private

  def catalog_item?
    room_id.nil?
  end

  def catalog_icon_required
    errors.add(:icon, "é obrigatório") unless icon.attached?
  end

  def icon_type_ok
    return unless icon.attached?
    ok = %w[image/svg+xml image/png image/jpeg image/webp]
    errors.add(:icon, "deve ser SVG/PNG/JPG/WEBP") unless ok.include?(icon.content_type)
  end
end
