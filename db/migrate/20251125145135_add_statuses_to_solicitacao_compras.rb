class AddStatusesToSolicitacaoCompras < ActiveRecord::Migration[8.0]
  def change
    add_column :solicitacao_compras, :status_autorizacao, :integer, default: 0, null: false
    add_column :solicitacao_compras, :motivo_rejeicao,   :text
    add_column :solicitacao_compras, :status_compra,     :integer, default: 0, null: false
  end
end
