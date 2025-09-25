class Room < ApplicationRecord
    has_many :reservations, dependent: :destroy
    belongs_to :device, optional: true
    has_many :room_items, dependent: :destroy
    belongs_to :room_group, optional: true
    has_rich_text :observacao
    has_rich_text :regras_de_uso

    accepts_nested_attributes_for :room_items, allow_destroy: true
    has_one_attached :photo
    validates :device_id, presence: true, if: -> { espaco_comun == true }

    validates :name, presence: true


end
