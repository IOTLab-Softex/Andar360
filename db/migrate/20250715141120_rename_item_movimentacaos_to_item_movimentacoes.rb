class RenameItemMovimentacaosToItemMovimentacoes < ActiveRecord::Migration[7.0]
  def change
    rename_table :item_movimentacaos, :item_movimentacoes
  end
end
