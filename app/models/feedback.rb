class Feedback < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :resolved_by, class_name: "User", optional: true

  has_many_attached :attachments

  enum :category, { bug: 0, melhoria: 1, ideia: 2, outro: 3 }, prefix: true
  enum :status,   { aberto: 0, em_andamento: 1, resolvido: 2, ignorado: 3 }, prefix: true
  enum :severity, { baixa: 0, media: 1, alta: 2, critica: 3 }, prefix: true

  validates :message, presence: true, length: { minimum: 5 }
  validates :category, :status, :severity, presence: true
end
