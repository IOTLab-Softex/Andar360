# app/models/manutencao_programada.rb
class ManutencaoProgramada < ApplicationRecord
  include Recente
  include Avisavel

  has_many_attached :arquivos
  has_many :arquivo_anexos, dependent: :destroy
  has_many :checklist_items, dependent: :destroy
  accepts_nested_attributes_for :checklist_items, allow_destroy: true
  has_many :ocorrencias, as: :ocorrenciavel, dependent: :destroy

  after_commit :notificar_se_em_periodo, on: %i[create update]
  before_validation :normalizar_data_prevista!

  attribute :dias_para_aviso, :integer, default: 1

   validates :titulo,       presence: { message: "não pode ficar em branco" }
  validates :data_prevista, presence: { message: "deve ser informada" }
  validates :observacao,   presence: { message: "não pode ficar em branco" },
                           length:   { minimum: 5, message: "está muito curta (mínimo 5 caracteres)" }
  # (opcional) garanta que dias_para_aviso seja número não-negativo
  validates :dias_para_aviso, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  
  # 🔑 Mapa normalizado (sem acentos, minúsculo)
  PERIODOS = {
    "diario"         => 1.day,
    "semanal"        => 1.week,
    "quinzenal"      => 15.days,
    "mensal"         => 1.month,
    "bimestral"      => 2.months,
    "trimestral"     => 3.months,
    "quadrimestral"  => 4.months,
    "semestral"      => 6.months,
    "anual"          => 1.year,
    "bienal"         => 2.years,
    "trienal"        => 3.years
  }.freeze

  # Aceita sinônimos/variações (com/sem acento, feminino/masc.)
  PERIODOS_ALIAS = {
    "diária" => "diario", "diaria" => "diario", "diário" => "diario", "diario" => "diario",
    "mensal" => "mensal", "mensal " => "mensal",  # com espaço
    # adicione outras variações se precisar
  }.freeze

  def self.normalize_periodicidade(raw)
    base = I18n.transliterate(raw.to_s).downcase.strip # tira acento/maiusc/espaço
    PERIODOS_ALIAS[base] || base
  end

  def delta_for_periodicidade
    key = self.class.normalize_periodicidade(periodicidade)
    PERIODOS[key]
  end

  # ===== Scopes =====
  scope :precisa_renovar, -> {
    where.not(data_prevista: nil)
      .where('DATE(data_prevista) < ?', Date.current)
      .where.not(periodicidade: [nil, ""])
  }

  scope :vence_hoje, -> {
    where.not(data_prevista: nil)
      .where('DATE(data_prevista) = ?', Date.current)
  }

  scope :em_periodo_de_aviso, -> {
    where.not(data_prevista: nil).where(<<~SQL)
      (
        (dias_para_aviso IS NOT NULL
         AND CURRENT_DATE BETWEEN (DATE(data_prevista) - dias_para_aviso) AND DATE(data_prevista))
        OR
        (data_de_aviso IS NOT NULL
         AND CURRENT_DATE BETWEEN DATE(data_de_aviso) AND DATE(data_prevista))
      )
    SQL
  }

  # ===== Métodos =====
  def proxima_data(a_partir_de: data_prevista)
    return nil if a_partir_de.blank?
    delta = delta_for_periodicidade
    return nil if delta.blank?
    (a_partir_de.to_date + delta).to_date
  end

  def avancar_ate_futuro!(referencia: Date.current)
    return false if data_prevista.blank?
    delta = delta_for_periodicidade
    return false if delta.blank?

    ref  = referencia.to_date
    nova = data_prevista.to_date
    while nova < ref
      nova = (nova + delta).to_date
    end

    if nova != data_prevista.to_date
      Rails.logger.info("[MP ##{id}] Avançando de #{data_prevista} -> #{nova} (#{periodicidade})")
      update!(data_prevista: nova)
      ajustar_data_de_aviso!
      true
    else
      false
    end
  end

  def ajustar_data_de_aviso!
    return unless dias_para_aviso.present? && data_prevista.present?
    self.data_de_aviso = (data_prevista.to_date - dias_para_aviso.days)
    save! if changed?
  end

  # Serviço de classe: renova só quem precisa
  def self.renovar_pendentes!(referencia: Date.current)
    count = 0
    precisa_renovar.find_each do |m|
      count += 1 if m.avancar_ate_futuro!(referencia: referencia)
    end
    Rails.logger.info("[MP] Renovadas #{count} pendentes.")
    count
  end

  private

  def normalizar_data_prevista!
    return if data_prevista.blank?
    delta = delta_for_periodicidade
    return if delta.blank?

    ref  = Date.current
    nova = data_prevista.to_date
    while nova < ref
      nova = (nova + delta).to_date
    end

    if nova != data_prevista.to_date
      Rails.logger.info("[MP ##{id}] Normalizando data_prevista #{data_prevista} -> #{nova} (#{periodicidade})")
      self.data_prevista = nova
    end

    self.data_de_aviso = (self.data_prevista.to_date - dias_para_aviso.days) if dias_para_aviso.present?
  end

  def notificar_se_em_periodo
    NotificationService.notify_users_for(self, only_if_in_period: true)
  end
end
