class RoomItem < ApplicationRecord
  PRESET_ICONS = {
    "chair" => { label: "Cadeira", fa: "fa-chair", filename: "cadeira.svg", svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M7 3h10a2 2 0 0 1 2 2v7a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2Zm-1 13h12v3h2v2h-4v-3H8v3H4v-2h2v-3Z"/></svg>' },
    "table" => { label: "Mesa", fa: "fa-table", filename: "mesa.svg", svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M3 5h18v4H3V5Zm2 6h2v8H5v-8Zm12 0h2v8h-2v-8Zm-8 0h6v2H9v-2Z"/></svg>' },
    "tv" => { label: "TV", fa: "fa-tv", filename: "tv.svg", svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M4 5h16a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2h-7v2h4v2H7v-2h4v-2H4a2 2 0 0 1-2-2V7a2 2 0 0 1 2-2Zm0 2v9h16V7H4Z"/></svg>' },
    "projector" => { label: "Projetor", fa: "fa-video", filename: "projetor.svg", svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M4 7h12a3 3 0 0 1 3 3v1.2l3-2V17l-3-2V16a3 3 0 0 1-3 3H4a3 3 0 0 1-3-3v-6a3 3 0 0 1 3-3Zm0 2a1 1 0 0 0-1 1v6a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1v-6a1 1 0 0 0-1-1H4Zm2 2h5v2H6v-2Z"/></svg>' },
    "wifi" => { label: "Wi-Fi", fa: "fa-wifi", filename: "wifi.svg", svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M12 18.5 15 22H9l3-3.5ZM3 9.7C8.1 5.4 15.9 5.4 21 9.7l-1.8 2.1c-4.1-3.5-10.3-3.5-14.4 0L3 9.7Zm3.7 4.3c3-2.5 7.6-2.5 10.6 0l-1.8 2.1c-2-1.7-5-1.7-7 0L6.7 14ZM.1 5.5c6.8-5.7 17-5.7 23.8 0l-1.8 2.1c-5.8-4.8-14.4-4.8-20.2 0L.1 5.5Z"/></svg>' },
    "microphone" => { label: "Microfone", fa: "fa-microphone", filename: "microfone.svg", svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M12 2a4 4 0 0 1 4 4v6a4 4 0 0 1-8 0V6a4 4 0 0 1 4-4Zm7 10a7 7 0 0 1-6 6.9V22h4v2H7v-2h4v-3.1A7 7 0 0 1 5 12h2a5 5 0 0 0 10 0h2Z"/></svg>' },
    "speaker" => { label: "Caixa de som", fa: "fa-volume-high", filename: "caixa-de-som.svg", svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M4 9h4l6-5v16l-6-5H4V9Zm13.2-2.3a8 8 0 0 1 0 10.6l-1.5-1.3a6 6 0 0 0 0-8l1.5-1.3Zm3-2.7a12 12 0 0 1 0 16l-1.5-1.3a10 10 0 0 0 0-13.4L20.2 4Z"/></svg>' },
    "board" => { label: "Quadro", fa: "fa-chalkboard", filename: "quadro.svg", svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M3 4h18v12H3V4Zm2 2v8h14V6H5Zm5 12h4v2h3v2H7v-2h3v-2Z"/></svg>' },
    "computer" => { label: "Computador", fa: "fa-desktop", filename: "computador.svg", svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M3 4h18a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2h-7v2h4v2H6v-2h4v-2H3a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2Zm0 2v10h18V6H3Z"/></svg>' },
    "coffee" => { label: "Cafe", fa: "fa-mug-hot", filename: "cafe.svg", svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M4 8h12v7a5 5 0 0 1-5 5H9a5 5 0 0 1-5-5V8Zm14 2h1a3 3 0 0 1 0 6h-1v-2h1a1 1 0 0 0 0-2h-1v-2ZM7 2h2v4H7V2Zm4 0h2v4h-2V2Z"/></svg>' },
    "water" => { label: "Agua", fa: "fa-bottle-water", filename: "agua.svg", svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M9 2h6v4l2 3v11a2 2 0 0 1-2 2H9a2 2 0 0 1-2-2V9l2-3V2Zm2 2v2h2V4h-2ZM9 11v9h6v-9H9Zm1 2h4v2h-4v-2Z"/></svg>' },
    "outlet" => { label: "Tomada", fa: "fa-plug", filename: "tomada.svg", svg: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M8 2h2v6h4V2h2v6h2v5a6 6 0 0 1-5 5.9V22h-2v-3.1A6 6 0 0 1 6 13V8h2V2Zm0 8v3a4 4 0 0 0 8 0v-3H8Z"/></svg>' }
  }.freeze

  belongs_to :room, optional: true, inverse_of: :room_items
  has_one_attached :icon

  # ID do item de catálogo vindo do form (não salvo em banco)
  attr_accessor :catalog_item_id, :preset_icon

  validates :name, presence: true
  validates :quantity, numericality: { greater_than: 0 }

  # 🔴 Ícone obrigatório só para itens de catálogo (room_id nil)
  validate :catalog_icon_required, if: :catalog_item?

  # 🔎 Tipo do ícone, só quando anexado
  validate :icon_type_ok

  # 👉 Preenche a partir do catálogo quando vier catalog_item_id
  before_validation :hydrate_from_catalog, if: -> { catalog_item_id.present? }

  scope :catalog, -> { where(room_id: nil).order(:name) }
  scope :by_room, ->(room_id) { where(room_id:) }

  def self.preset_icons
    PRESET_ICONS
  end

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

  # 🌟 Aqui é o método que estava faltando
  def hydrate_from_catalog
    return if catalog_item_id.blank?

    catalog = RoomItem.catalog.find_by(id: catalog_item_id)
    return unless catalog

    # Copia o nome se ainda não foi preenchido manualmente
    self.name ||= catalog.name

    # Copia o ícone do catálogo se o item da sala ainda não tiver
    if catalog.icon.attached? && !icon.attached?
      self.icon.attach(catalog.icon.blob)
    end
  end
end
