class Chamado < ApplicationRecord
  include Recente

  has_many_attached :fotos
  belongs_to :room, optional: true
  belongs_to :solicitante, class_name: "Participant", optional: true
  has_many :notifications, as: :notificavel, dependent: :destroy

  # 🔹 Relações que tinham antes
  has_many :ocorrencias, as: :ocorrenciavel, dependent: :destroy
  has_many :arquivos_anexos_chamado,
           class_name: 'ArquivoAnexo',
           dependent: :destroy

  validates :titulo,      presence: true
  validates :responsavel, presence: true

  scope :password_recovery_support_requests, -> { where(password_recovery_support_request: true) }

  # --------------------------------------------------------------------
  # 🔹 SCOPE: Chamados visíveis para o usuário atual
  # --------------------------------------------------------------------
  scope :visiveis_para, ->(user) {
    return none unless user&.participant
    return none unless user.client?

    participant_id = user.participant.id
    nome_resp = user.participant.name

    where("chamados.solicitante_id = :pid OR chamados.responsavel = :nome_resp",
          pid: participant_id,
          nome_resp: nome_resp)
  }

  # --------------------------------------------------------------------
  # 🔹 LOCALIZA O USER DO RESPONSÁVEL (texto → Participant → User)
  # --------------------------------------------------------------------
  def usuario_responsavel
    return if responsavel.blank?

    participant = Participant.find_by(name: responsavel)
    User.find_by(participant_id: participant&.id)
  end

  def password_recovery_target_user
    solicitante&.user || User.find_by(participant_id: solicitante_id)
  end

  def password_recovery_reset_link_sent?
    password_recovery_reset_link_sent_at.present?
  end

  def status_concluido?
    ["Concluído", "Concluido", "Concluída", "Concluida", "Finalizada"].include?(status.to_s)
  end

  # --------------------------------------------------------------------
  # 🔹 QUEM DEVE RECEBER A NOTIFICAÇÃO DO CHAMADO?
  # --------------------------------------------------------------------
  def usuarios_para_notificar
    chamado_empresa_id = solicitante&.grupo_empresa_id

    users =
      User.includes(:participant).find_each.select do |user|
        if user.admin? || user.operador?
          true
        else
          # Se não há empresa vinculada ao chamado => só admin vê
          next false if chamado_empresa_id.blank?

          user_empresa_id = user.participant&.grupo_empresa_id

          # Cliente só vê se marcado como "exibir_no_app"
          if user.client?
            next false unless respond_to?(:exibir_no_app?) && exibir_no_app?
          end

          user_empresa_id == chamado_empresa_id
        end
      end

    # 🔹 responsável SEMPRE recebe
    if (r = usuario_responsavel)
      users << r
    end

    users.uniq
  end

  # --------------------------------------------------------------------
  # 🔹 Criação das notificações
  # --------------------------------------------------------------------
  def criar_notificacao_para(user, titulo, corpo)
    Notification.create!(
      user:        user,
      notificavel: self,
      titulo:      titulo,
      corpo:       corpo,
      lida:        false,
      url:         Rails.application.routes.url_helpers.chamado_path(self)
    )
  end

  after_commit :notificar_chamado_criado,     on: :create
  after_commit :notificar_chamado_atualizado, on: :update

  def notificar_chamado_criado
    usuarios_para_notificar.each do |user|
      criar_notificacao_para(
        user,
        "Chamado criado: #{titulo}",
        "O chamado '#{titulo}' foi criado com status: #{status}."
      )
    end
  end

  def notificar_chamado_atualizado
    return unless previous_changes.key?("status") || previous_changes.key?("responsavel")
    return ocultar_notificacoes_para_todos! if status_concluido?

    usuarios_para_notificar.each do |user|
      criar_notificacao_para(
        user,
        "Chamado atualizado: #{titulo}",
        "O chamado '#{titulo}' foi atualizado com status: #{status}."
      )
    end
  end

  def ocultar_notificacoes_para_todos!
    notifications.update_all(lida: true)
  end
end
