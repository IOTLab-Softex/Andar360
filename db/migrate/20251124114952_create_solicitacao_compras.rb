class CreateSolicitacaoCompras < ActiveRecord::Migration[8.0]
  def change
    create_table :solicitacao_compras do |t|
      t.string  :colaborador
      t.string  :setor
      t.date    :item_data
      t.string  :item_descricao
      t.decimal :valor_estimado, precision: 10, scale: 2
      t.text    :justificativa
      t.integer :forma_pagamento
      t.integer :parcelas
      t.string  :cidade
      t.date    :data_solicitacao
      t.string  :autorizado_por

      t.timestamps
    end
  end
end
