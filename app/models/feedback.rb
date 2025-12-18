class Feedback < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :resolved_by, class_name: "User", optional: true
  belongs_to :release, optional: true

  validates :release, presence: true, if: :needs_release?

  has_many_attached :attachments

  scope :sem_release, -> { where(release_id: nil) }
  scope :resolvidos,  -> { where(status: :resolvido) }

  enum :category, { bug: 0, melhoria: 1, ideia: 2, outro: 3 }, prefix: true
  enum :status,   { aberto: 0, em_andamento: 1, resolvido: 2, ignorado: 3 }, prefix: true
  enum :severity, { baixa: 0, media: 1, alta: 2, critica: 3 }, prefix: true

  validates :message,
            presence: { message: "não pode ficar em branco" },
            length: { minimum: 10, too_short: "precisa ter pelo menos %{count} caracteres" },
            allow_blank: true

  validates :category, :status, :severity, presence: true

  def resolvido?
    status == "resolvido"
  end

  def needs_release?
    status == "resolvido" && release_id.present?
  end
end
