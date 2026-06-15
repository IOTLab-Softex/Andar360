class SolicitacaoCompra < ApplicationRecord
  # ✅ forma_pagamento – sintaxe compatível (2 argumentos)
  enum :forma_pagamento, {
    a_vista:        0,
    cartao_credito: 1,
    faturado:       2
  }

  # ✅ novos enums de status
  enum :status_autorizacao, {
    pendente:   0,
    autorizado: 1,
    rejeitado:  2
  }

  enum :status_compra, {
    aguardando: 0,
    comprado:   1,
    cancelado:  2
  }

  has_many :itens,
           class_name: "SolicitacaoCompraItem",
           dependent: :destroy,
           inverse_of: :solicitacao_compra

  accepts_nested_attributes_for :itens, allow_destroy: true

  validates :colaborador, :setor, :justificativa, presence: true
  validate :deve_ter_ao_menos_um_item

  def total_geral
    total_itens = itens.sum { |i| i.valor_total.to_d }
    total_itens.positive? ? total_itens : (valor_estimado || 0).to_d
  end
 def compra_fechada?
    comprado? || cancelado?
  end
  private

  def deve_ter_ao_menos_um_item
    if itens.reject(&:marked_for_destruction?).blank?
      errors.add(:base, "Adicione pelo menos um item na solicitação")
    end
  end
end
