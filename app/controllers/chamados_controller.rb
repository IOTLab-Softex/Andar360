class ChamadosController < ApplicationController
  include VisualizacaoHelper
  before_action :authenticate_user!
  before_action :set_chamado, only: %i[ show edit update destroy change_status send_password_recovery_link ]
  before_action :authorize_chamado_access, only: %i[ show edit update destroy change_status send_password_recovery_link ]
  before_action :authorize_chamado_edit, only: %i[ edit update destroy ]
  # carregue coleções sempre que vai renderizar formulário
  before_action :prepare_collections, only: %i[new edit create update]
  # GET /chamados or /chamados.json
  def index
  if current_user.admin? || current_user.operador?
    @chamados = Chamado.all
  else
    @chamados = Chamado.visiveis_para(current_user)
  end

  # filtros já existentes...
  @chamados = @chamados.where(status: params[:status]) if params[:status].present? && params[:status] != "Todos os status"
  @chamados = @chamados.where(unidade: params[:unidade]) if params[:unidade].present? && params[:unidade] != "Todas as unidades"
  @chamados = @chamados.where(prioridade: params[:prioridade]) if params[:prioridade].present? && params[:prioridade] != "Todas as prioridades"
  @chamados = @chamados.where(responsavel: params[:responsavel]) if params[:responsavel].present? && params[:responsavel] != "Todos os responsáveis"
  @chamados = @chamados.password_recovery_support_requests if params[:password_recovery_support].present? && params[:password_recovery_support] == "Solicitou suporte de acesso"

  if params[:data_inicio].present? && params[:data_fim].present?
    @chamados = @chamados.where(data_resolucao: params[:data_inicio]..params[:data_fim])
  end
end


  # GET /chamados/1 or /chamados/1.json
  def show
marcar_como_visualizado("chamado", @chamado.id)

  end

  # GET /chamados/new
 def new

  if current_user.admin? || current_user.operador?
    @rooms_disponiveis = Room.where(espaco_comun: false).order(:name)
  else
    grupo_empresa = current_user.participant&.grupo_empresa&.nome
    @rooms_disponiveis = Room.where(espaco_comun: false).where("lower(dados_do_inquilino) LIKE ?", "%#{grupo_empresa&.downcase}%")
  end
  if current_user.admin? || current_user.role == "operador"
  @possiveis_responsaveis = Participant.order(:name)
else
  grupo_id = current_user.participant&.grupo_empresa_id
  @possiveis_responsaveis = Participant.where(grupo_empresa_id: grupo_id).order(:name)
end
  last_os_number = Chamado.order(:created_at).last&.id.to_i + 1
  os_formatada = "%04d" % last_os_number
  @chamado = Chamado.new(os: os_formatada)
  @chamado.responsavel ||= current_user.participant&.name

  @chamado.room_id ||= @rooms_disponiveis.first.id if @rooms_disponiveis.size == 1

end


  # GET /chamados/1/edit
  def edit
     if current_user.admin?
    @rooms_disponiveis = Room.where(espaco_comun: false).order(:name)
  else
    grupo_empresa = current_user.participant&.grupo_empresa&.nome
    @rooms_disponiveis = Room.where(espaco_comun: false).where("lower(dados_do_inquilino) LIKE ?", "%#{grupo_empresa&.downcase}%")
  end
  if current_user.admin? || current_user.role == "operador"
  @possiveis_responsaveis = Participant.order(:name)
else
  grupo_id = current_user.participant&.grupo_empresa_id
  @possiveis_responsaveis = Participant.where(grupo_empresa_id: grupo_id).order(:name)
end

  @chamado.room_id ||= @rooms_disponiveis.first.id if @rooms_disponiveis.size == 1

  end

  # POST /chamados or /chamados.json
def create
    last_os_number = Chamado.order(:created_at).last&.id.to_i + 1
    os_formatada   = "%04d" % last_os_number
    participant    = current_user.participant

    params_sanitizados = chamado_params.dup
    params_sanitizados[:status] = "Pendente" unless current_user.admin? || current_user.role == "operador"

    @chamado = Chamado.new(params_sanitizados.merge(
      os: os_formatada,
      solicitante: participant,
      solicitante_nome: participant&.name
    ))

    if @chamado.save
    redirect_to root_path, status: :see_other, notice: "Chamado criado com sucesso."
  else
    flash.now[:alert] = @chamado.errors.full_messages.to_sentence.presence || "Não foi possível salvar."
    render :new, status: :unprocessable_entity
  end
  end


def update
  atributos = chamado_params.except(:fotos)
  atributos = atributos.except(:status, :data_resolucao) unless current_user.admin? || current_user.operador?

  if @chamado.update(atributos)
    @chamado.fotos.attach(params[:chamado][:fotos]) if params.dig(:chamado, :fotos)
    
    redirect_to root_path, status: :see_other, notice: "Chamado atualizado com sucesso."
  else
    flash.now[:alert] = @chamado.errors.full_messages.to_sentence.presence || "Não foi possível atualizar."
    render :edit, status: :unprocessable_entity
  end
end

  # DELETE /chamados/1 or /chamados/1.json
  def destroy
    @chamado.destroy!

    respond_to do |format|
      format.html { redirect_to chamados_path, status: :see_other, notice: "Chamado excluído com sucesso." }

      format.json { head :no_content }
    end
  end

  def change_status
    unless usuario_pode_alterar_status?
      redirect_back fallback_location: chamados_path, alert: "Sem permissão para alterar o status."
      return
    end

    novo_status = params[:status].presence
    novo_status = proximo_status_chamado(@chamado.status) if novo_status.blank?

    unless status_valido?(novo_status)
      redirect_back fallback_location: chamados_path, alert: "Status inválido."
      return
    end

    status_normalizado = normalizar_status_chamado(novo_status)
    observacao = params[:observacao].to_s.strip
    proxima_data = params[:proxima_data].presence

    if status_normalizado == "Pendente" && (observacao.blank? || proxima_data.blank?)
      redirect_back fallback_location: chamados_path, alert: "Observação e próxima data são obrigatórias para Pendente."
      return
    end

    begin
      Chamado.transaction do
        @chamado.update!(status: status_normalizado)

        if status_normalizado == "Pendente"
          @chamado.ocorrencias.create!(
            data_ocorrencia: Time.current,
            descricao: observacao,
            proxima_data: proxima_data
          )
        end
      end

      redirect_back fallback_location: chamados_path, notice: "Status atualizado para #{status_normalizado}."
    rescue ActiveRecord::RecordInvalid => e
      mensagem = e.record.errors.full_messages.to_sentence.presence || "Não foi possível atualizar o status."
      redirect_back fallback_location: chamados_path, alert: mensagem
    end
  end

  def send_password_recovery_link
    unless usuario_pode_enviar_link_recuperacao?
      redirect_back fallback_location: chamados_path, alert: "Sem permissao para enviar o link de redefinicao."
      return
    end

    unless @chamado.password_recovery_support_request?
      redirect_back fallback_location: chamados_path, alert: "Este chamado nao pertence ao fluxo de recuperacao por suporte."
      return
    end

    if @chamado.password_recovery_reset_link_sent?
      redirect_back fallback_location: chamados_path, alert: "O link de redefinicao ja foi enviado para este chamado."
      return
    end

    user = @chamado.password_recovery_target_user
    if user.blank? || user.email.blank?
      redirect_back fallback_location: chamados_path, alert: "Nao foi encontrado um usuario com e-mail valido para este chamado."
      return
    end

    MailSettings.apply!
    user.send_reset_password_instructions

    observacao_atual = @chamado.observacao.to_s.strip
    complemento = [
      observacao_atual.presence,
      "Link de redefinicao enviado por #{current_user.participant&.name || current_user.email || 'suporte'} em #{I18n.l(Time.current, format: :short)}."
    ].compact.join("\n\n")

    @chamado.update!(
      status: "Concluído",
      password_recovery_reset_link_sent_at: Time.current,
      observacao: complemento
    )

    redirect_back fallback_location: chamados_path, notice: "Link de redefinicao enviado com sucesso e chamado concluido."
  rescue Errno::ECONNREFUSED, SocketError, IOError, SystemCallError
    redirect_back fallback_location: chamados_path, alert: "Nao foi possivel conectar ao servidor de e-mail configurado. Revise as configuracoes SMTP."
  rescue Net::SMTPAuthenticationError, Net::SMTPServerBusy, Net::SMTPSyntaxError, Net::SMTPFatalError, Net::SMTPUnknownError => e
    redirect_back fallback_location: chamados_path, alert: "Falha ao enviar o e-mail de redefinicao: #{e.message}"
  end
  
def remove_foto
  foto = ActiveStorage::Blob.find_signed(params[:foto_id])
  foto.attachments.first&.purge_later
  redirect_back fallback_location: chamados_path, notice: "Foto removida com sucesso."
end

 def anexar_arquivo
    @chamado = Chamado.find(params[:id])
    arquivo_anexo = @chamado.arquivos_anexos_chamado.build(nome: params[:nome])
    arquivo_anexo.arquivo.attach(params[:arquivo])

    if arquivo_anexo.save
      redirect_to edit_chamado_path(@chamado), notice: "Arquivo anexado com sucesso."
    else
      redirect_to edit_chamado_path(@chamado), alert: "Erro ao anexar o arquivo."
    end
  end
  
  private

   def prepare_collections
    if current_user.admin? || current_user.role == "operador"
      @rooms_disponiveis      = Room.where(espaco_comun: false).order(:name)
      @possiveis_responsaveis = Participant.order(:name)
    else
      grupo_empresa  = current_user.participant&.grupo_empresa&.nome
      @rooms_disponiveis = Room.where(espaco_comun: false)
                               .where("lower(dados_do_inquilino) LIKE ?", "%#{grupo_empresa&.downcase}%")
      grupo_id = current_user.participant&.grupo_empresa_id
      @possiveis_responsaveis = Participant.where(grupo_empresa_id: grupo_id).order(:name)
    end
  end
    # Use callbacks to share common setup or constraints between actions.
def set_chamado
  @chamado = Chamado.find(params[:id])
end


    # Only allow a list of trusted parameters through.
def chamado_params
  params.require(:chamado).permit(:room_id, :os, :titulo, :prioridade, :status, :data_resolucao, :exibir_no_app, :local, :responsavel, :observacao, fotos: [])
end

 def chamado_params_com_anexo
    params.require(:chamado).permit(:nome, :arquivo) # Certifique-se de permitir os atributos 'nome' e 'arquivo'
  end

  def usuario_pode_alterar_status?
    return false unless current_user

    current_user.admin? || current_user.operador?
  end

  def authorize_chamado_access
    return if current_user.admin? || current_user.operador?
    return unless current_user.client?
    return unless current_user.participant
    return if action_name == "send_password_recovery_link" && usuario_pode_enviar_link_recuperacao?

    eh_solicitante = @chamado.solicitante_id.present? && @chamado.solicitante_id == current_user.participant.id
    eh_responsavel = @chamado.responsavel.present? && @chamado.responsavel == current_user.participant.name

    return if eh_solicitante || eh_responsavel

    redirect_to root_path, alert: "Você não tem acesso a este chamado."
  end

  def authorize_chamado_edit
    return if current_user.admin? || current_user.operador?
    return unless current_user.client?
    return unless current_user.participant

    eh_solicitante = @chamado.solicitante_id.present? && @chamado.solicitante_id == current_user.participant.id
    eh_responsavel = @chamado.responsavel.present? && @chamado.responsavel == current_user.participant.name

    # Client responsável (e não solicitante) só pode mudar status, não editar/excluir
    if eh_responsavel && !eh_solicitante
      redirect_to chamado_path(@chamado), alert: "Responsável não pode editar este chamado."
    end
  end

  def status_valido?(status)
    ["Pendente", "Em andamento", "Concluído"].include?(normalizar_status_chamado(status.to_s))
  end

  def usuario_pode_enviar_link_recuperacao?
    return false unless current_user
    return false unless current_user.participant
    return false unless current_user.participant.sub_grupo_empresa&.can_support_access?
    return false unless @chamado.password_recovery_support_request?
    return false unless @chamado.solicitante&.grupo_empresa_id.present?

    @chamado.solicitante.grupo_empresa_id == current_user.participant.grupo_empresa_id
  end

  def normalizar_status_chamado(status)
    map = {
      "Solicitada" => "Pendente",
      "Finalizada" => "Concluído",
      "Concluida" => "Concluído",
      "Concluido" => "Concluído"
    }
    map[status] || status
  end

  def proximo_status_chamado(status_atual)
    ordem = ["Pendente", "Em andamento", "Concluído"]
    status_atual = normalizar_status_chamado(status_atual.to_s)
    idx = ordem.index(status_atual) || 0
    ordem[(idx + 1) % ordem.length]
  end

end
