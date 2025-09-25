# app/models/item.rb
class Item < ApplicationRecord
  has_one_attached :foto

has_many :item_movimentacoes, class_name: "ItemMovimentacao"


end
