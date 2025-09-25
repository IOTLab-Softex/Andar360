class Chamado < ApplicationRecord
    include Recente
    has_many_attached :fotos
    belongs_to :room, optional: true
    belongs_to :solicitante, class_name: "Participant", optional: true
     has_many :ocorrencias, as: :ocorrenciavel, dependent: :destroy
       has_many :arquivos_anexos_chamado, class_name: 'ArquivoAnexo', dependent: :destroy

    after_commit :notificar_chamado_criado, on: :create
  after_commit :notificar_chamado_atualizado, on: :update

  private

  def notificar_chamado_criado
    User.includes(:participant).find_each do |user|
  next if user.client? && !exibir_no_app?

  # Se for cliente, só notifica se estiver no mesmo grupo da empresa do chamado
  if user.client?
    chamado_grupo_id = self.solicitante&.grupo_empresa_id
    user_grupo_id = user.participant&.grupo_empresa_id
    next if chamado_grupo_id.blank? || user_grupo_id != chamado_grupo_id
  end

  Notification.create!(
    user: user,
    notificavel: self,
    titulo: "Chamado atualizado: #{titulo_formatado}",
    corpo: "O chamado '#{titulo_formatado}' foi atualizado com status: #{status}.",
    lida: false
  )
end

  end

  def notificar_chamado_atualizado
    return unless previous_changes.key?('status') || previous_changes.key?('responsavel')

    User.includes(:participant).find_each do |user|
  next if user.client? && !exibir_no_app?

  # Se for cliente, só notifica se estiver no mesmo grupo da empresa do chamado
  if user.client?
    chamado_grupo_id = self.solicitante&.grupo_empresa_id
    user_grupo_id = user.participant&.grupo_empresa_id
    next if chamado_grupo_id.blank? || user_grupo_id != chamado_grupo_id
  end

  Notification.create!(
    user: user,
    notificavel: self,
    titulo: "Chamado atualizado: #{titulo_formatado}",
    corpo: "O chamado '#{titulo_formatado}' foi atualizado com status: #{status}.",
    lida: false
  )
end

  end

  def titulo_formatado
    titulo.presence || "##{id}"
  end
end
