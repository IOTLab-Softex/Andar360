class CreateItemMovimentacaos < ActiveRecord::Migration[8.0]
  def change
    create_table :item_movimentacaos do |t|
      t.references :item, null: false, foreign_key: true
      t.string :empresa
      t.string :responsavel
      t.text :descricao
      t.string :tipo

      t.timestamps
    end
  end
end
