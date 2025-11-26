class SolicitacaoCompraItem < ApplicationRecord
  belongs_to :solicitacao_compra

  validates :descricao, :quantidade, :valor_unitario, presence: true

  def valor_total
    total || quantidade.to_d * valor_unitario.to_d
  end
end
