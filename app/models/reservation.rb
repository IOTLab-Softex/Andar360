class Reservation < ApplicationRecord
  include Avisavel
  attr_accessor :rules_accepted
  belongs_to :room
  has_and_belongs_to_many :participants
  has_many :access_logs, dependent: :delete_all
  belongs_to :grupo_empresa, optional: true

  belongs_to :solicitante, class_name: "Participant", foreign_key: "solicitante_id", optional: true
  belongs_to :responsavel, class_name: "Participant", foreign_key: "responsavel_id", optional: true

  validates :title, :starts_at, :ends_at, :room_id, :solicitante_id, :responsavel_id, presence: true
  validate :must_accept_rules_if_required
  # Participantes são opcionais → não precisam de validação

  after_initialize do
    self.sent_to_facial = false if self.sent_to_facial.nil?
  end

  before_destroy :remover_participantes_do_dispositivo_se_necessario
  

  
  private
   def must_accept_rules_if_required
    return unless Setting.first&.require_room_rules_ack?
    unless rules_accepted.to_s == "1"
      errors.add(:base, "É necessário aceitar as regras da sala antes de criar a reserva.")
    end
  end
  
  def remover_participantes_do_dispositivo_se_necessario
    return unless Time.current >= starts_at && room&.device.present?

    participantes_ids = []
    participantes_ids << solicitante_id if solicitantes_enviados_em.present?
    participantes_ids << responsavel_id if solicitantes_enviados_em.present?
    participantes_ids += participants.pluck(:id) if participantes_enviados_em.present?

    participantes_ids.uniq!
    Rails.logger.info "[🧹] Reserva #{id} excluída após início. Agendando remoção dos IDs: #{participantes_ids.inspect}"
    RemoverParticipantesDoDispositivoJob.perform_later(participantes_ids, room.device.id)
  end
end
