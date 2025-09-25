# app/models/manutencao_programada.rb
class ManutencaoProgramada < ApplicationRecord
  include Recente
  include Avisavel

  has_many_attached :arquivos
  has_many :arquivo_anexos, dependent: :destroy
  has_many :checklist_items, dependent: :destroy
  accepts_nested_attributes_for :checklist_items, allow_destroy: true
  has_many :ocorrencias, as: :ocorrenciavel, dependent: :destroy

  # Notifica sempre que criar/atualizar, mas só se estiver no período de aviso
  after_commit :notificar_se_em_periodo, on: %i[create update]
  attribute :dias_para_aviso, :integer, default: 1
  private

  def notificar_se_em_periodo
    NotificationService.notify_users_for(self, only_if_in_period: true)
  end
end
