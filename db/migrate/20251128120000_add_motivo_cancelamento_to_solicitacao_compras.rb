# db/migrate/20251128120000_add_motivo_cancelamento_to_solicitacao_compras.rb
class AddMotivoCancelamentoToSolicitacaoCompras < ActiveRecord::Migration[8.0]
  def change
    add_column :solicitacao_compras, :motivo_cancelamento_compra, :text
  end
end
