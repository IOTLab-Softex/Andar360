class Feedback < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :resolved_by, class_name: "User", optional: true

  has_many_attached :attachments

  enum :category, { bug: 0, melhoria: 1, ideia: 2, outro: 3 }, prefix: true
  enum :status,   { aberto: 0, em_andamento: 1, resolvido: 2, ignorado: 3 }, prefix: true
  enum :severity, { baixa: 0, media: 1, alta: 2, critica: 3 }, prefix: true

  # presença com mensagem PT-BR
  validates :message,
    presence: { message: "não pode ficar em branco" }

  # tamanho mínimo; só roda se não estiver em branco
  validates :message,
    length: { minimum: 10, too_short: "precisa ter pelo menos %{count} caracteres" },
    allow_blank: true

  validates :category, :status, :severity, presence: true
end
