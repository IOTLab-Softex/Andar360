class ItemMovimentacao < ApplicationRecord
  self.table_name = "item_movimentacoes"
  belongs_to :item
end
