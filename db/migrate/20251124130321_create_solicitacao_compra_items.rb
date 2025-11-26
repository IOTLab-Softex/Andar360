class CreateSolicitacaoCompraItems < ActiveRecord::Migration[8.0]
  def change
    create_table :solicitacao_compra_items do |t|
      t.references :solicitacao_compra, null: false, foreign_key: true
      t.string :descricao
      t.integer :quantidade
      t.decimal :valor_unitario, precision: 10, scale: 2
      t.decimal :total, precision: 10, scale: 2

      t.timestamps
    end
  end
end
