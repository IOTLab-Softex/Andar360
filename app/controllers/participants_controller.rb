class ParticipantsController < ApplicationController
  before_action :require_admin_or_operador!, only: [:block_access, :unblock_access]

  def new
    @participant = Participant.new
  end

  def create
  @participant = Participant.new(participant_params)
  if @participant.save
    if params[:criar_usuario] == "1"
      senha = params[:senha_gerada] || SecureRandom.hex(4)

      user = User.create!(
        cpf: @participant.cpf, # <- CPF como login
        email: @participant.email,
        password: senha,
        password_confirmation: senha,
        role: params[:user_role],
        participant_id: @participant.id,
        force_password_change: true,
      )

      Rails.logger.info "Usuário criado: #{user.email} - Senha: #{senha}"
    end

    redirect_to participants_path, notice: "Participante criado com sucesso!"
  else
    flash.now[:alert] = "Não foi possível salvar o participante. Verifique os erros."
    render action: :new, status: :unprocessable_entity
  end
end

def update
  @participant = Participant.find(params[:id])
  if @participant.update(participant_params)
    if params[:criar_usuario] == "1"
      senha = params[:manter_senha] == "1" ? nil : (params[:senha_gerada] || SecureRandom.hex(4))

      if @participant.user.present?
        user = @participant.user
        user.role = params[:user_role] if params[:user_role].present?

        if senha.present?
          user.password = senha
          user.password_confirmation = senha
          user.force_password_change = true
          Rails.logger.info "Senha atualizada para #{user.email || user.cpf} - Nova senha: #{senha}"
        elsif user.force_password_change?
          user.force_password_change = false
        end

        user.save!
      else
        user = User.create!(
          cpf: @participant.cpf,
          email: @participant.email,
          password: senha || SecureRandom.hex(4),
          password_confirmation: senha || SecureRandom.hex(4),
          role: params[:user_role],
          participant_id: @participant.id,
          force_password_change: true,
        )
        Rails.logger.info "Usuário criado: #{user.email || user.cpf} - Senha: #{senha}"
      end
    elsif params[:criar_usuario] != "1" && @participant.user.present?
      @participant.user.destroy
      Rails.logger.info "Acesso removido para o participante #{@participant.id}"
    end

    redirect_to participants_path, notice: "Participante atualizado com sucesso."
  else
    flash.now[:alert] = "Não foi possível atualizar o participante. Verifique os erros."
    render :edit, status: :unprocessable_entity
  end
end


  def edit
    @participant = Participant.find(params[:id])
  end

  def update
  @participant = Participant.find(params[:id])
  if @participant.update(participant_params)
    if params[:criar_usuario] == "1"
      senha = params[:manter_senha] == "1" ? nil : (params[:senha_gerada] || SecureRandom.hex(4))

      if @participant.user.present?
        user = @participant.user
        user.role = params[:user_role] if params[:user_role].present?

        if senha.present?
          user.password = senha
          user.password_confirmation = senha
          user.force_password_change = true
          Rails.logger.info "Senha atualizada para #{user.email || user.cpf} - Nova senha: #{senha}"
        elsif user.force_password_change?
          user.force_password_change = false
        end

        user.save!
      else
        user = User.create!(
          cpf: @participant.cpf,
          email: @participant.email,
          password: senha || SecureRandom.hex(4),
          password_confirmation: senha || SecureRandom.hex(4),
          role: params[:user_role],
          participant_id: @participant.id,
          force_password_change: true,
        )
        Rails.logger.info "Usuário criado: #{user.email || user.cpf} - Senha: #{senha}"
      end
    elsif params[:criar_usuario] != "1" && @participant.user.present?
      @participant.user.destroy
      Rails.logger.info "Acesso removido para o participante #{@participant.id}"
    end

    redirect_to participants_path, notice: "Participante atualizado com sucesso."
  else
    flash.now[:alert] = "Não foi possível atualizar o participante. Verifique os erros."
    render :edit, status: :unprocessable_entity
  end
end

  def camera
    render layout: false
  end

  # app/controllers/participants_controller.rb
  # app/controllers/participants_controller.rb
  def index
  tab = params[:tab].presence || "ativos"

  # --- Empresa padrão + persistência em sessão ---
  if current_user.admin? || current_user.operador?
    if params.key?(:grupo_empresa_id)
      # salva inclusive "" (TODOS)
      session[:participants_grupo_empresa_id] = params[:grupo_empresa_id]
    end

    # pega do params (mesmo que seja "") ou da sessão
    @selected_grupo_empresa_id =
      if params.key?(:grupo_empresa_id)
        params[:grupo_empresa_id]
      else
        session[:participants_grupo_empresa_id]
      end

    # se não tem nada (nil), aplica padrão (segunda empresa)
    if @selected_grupo_empresa_id.nil?
      @selected_grupo_empresa_id = GrupoEmpresa.order(:nome).second&.id
      session[:participants_grupo_empresa_id] = @selected_grupo_empresa_id
    end
  else
    @selected_grupo_empresa_id = current_user.participant&.grupo_empresa_id
  end

  # "" => TODOS (não filtra). Qualquer valor => filtra
  empresa_filtro = @selected_grupo_empresa_id.presence

  # base SEMPRE já vem com filtro de empresa aplicado (quando houver)
  base = scoped_participants
  base = base.where(grupo_empresa_id: empresa_filtro) if empresa_filtro

  # --- Contagens (respeitando empresa) ---
  @count_ativos    = base.where("excluido = ? OR excluido IS NULL", false).count
  @count_excluidos = current_user.admin? ? base.where(excluido: true).count : 0

  ids_pend = SolicitacaoParticipante.where(status: "pendente").pluck(:participant_id)
  @count_pendentes = base.where(id: ids_pend).count

  aprov_scope  = FormularioCadastro.where(status: "pendente")
  reprov_scope = FormularioCadastro.where(status: "reprovado")
  if empresa_filtro
    aprov_scope  = aprov_scope.where(grupo_empresa_id: empresa_filtro)
    reprov_scope = reprov_scope.where(grupo_empresa_id: empresa_filtro)
  end
  @count_aprovacoes = aprov_scope.count
  @count_reprovados = reprov_scope.count

  # --- Tabs ---
  case tab
  when "aprovacoes"
    scope = FormularioCadastro.where(status: "pendente")
    scope = scope.where(grupo_empresa_id: empresa_filtro) if empresa_filtro
    @formularios_pendentes = scope.order(created_at: :desc)
    @participants = Participant.none

  when "reprovados"
    scope = FormularioCadastro.where(status: "reprovado")
    scope = scope.where(grupo_empresa_id: empresa_filtro) if empresa_filtro
    @formularios_reprovados = scope.order(created_at: :desc)
    @participants = Participant.none

  else
    # ✅ aqui estava o seu bug: @participants estava nil
    @participants = base.includes(:user)

    # --- filtros acesso/bloqueio ---
    if params[:user_access].present?
      case params[:user_access]
      when "with_user"
        @participants = @participants.joins(:user)
      when "without_user"
        @participants = @participants.left_outer_joins(:user).where(users: { id: nil })
      end
    end

    if params[:user_block].present? && ActiveRecord::Base.connection.column_exists?(:users, :blocked)
      case params[:user_block]
      when "blocked"
        @participants = @participants.joins(:user).where(users: { blocked: true })
      when "unblocked"
        @participants = @participants.joins(:user).where(users: { blocked: false })
      end
    end

    # --- sub-abas ---
    case tab
    when "ativos"
      @participants = @participants.where("excluido = ? OR excluido IS NULL", false)
    when "excluidos"
      @participants = @participants.where(excluido: true)
    when "pendentes"
      ids = SolicitacaoParticipante.where(status: "pendente").pluck(:participant_id)
      @participants = @participants.where(id: ids)
    end

    # --- filtros extras ---
    if params[:sub_grupo_empresa_id].present?
      @participants = @participants.where(sub_grupo_empresa_id: params[:sub_grupo_empresa_id])
    end

    if params[:search].present?
      q = "%#{params[:search]}%"
      @participants = @participants.where("name ILIKE :q OR cpf ILIKE :q", q: q)
    end
  end
end


  def delete_all
    unless current_user.admin?
      redirect_to participants_path, alert: "⚠️ Apenas administradores podem excluir todos os usuários."
      return
    end

    participants = scoped_participants
    total = 0
    pulados = []

    participants.each do |p|
      if Reservation.where("solicitante_id = :id OR responsavel_id = :id", id: p.id).exists? ||
         Reservation.joins(:participants).where(participants: { id: p.id }).exists?
        pulados << p.name
        next
      end

      p.destroy
      total += 1
    end

    mensagem = "🗑️ #{total} participante(s) foram excluídos com sucesso."
    mensagem += " ⚠️ Pulados: #{pulados.join(", ")}" if pulados.any?

    redirect_to participants_path, notice: mensagem
  end

  def destroy
    @participant = Participant.find(params[:id])

    if current_user.participant_id == @participant.id
      redirect_to participants_path, alert: "⚠️ Você não pode excluir a si mesmo!"
      return
    end

    if Reservation.where("solicitante_id = :id OR responsavel_id = :id", id: @participant.id).exists?
      redirect_to participants_path, alert: "⚠️ Este participante está vinculado a uma reserva e não pode ser excluído."
      return
    end

    @participant.destroy
    redirect_to participants_path, notice: "Participante excluído com sucesso."
  end

  def resgatar
    @participant = Participant.find(params[:id])
    @participant.update(excluido: false)
    redirect_to participants_path(tab: "ativos"), notice: "Participante resgatado com sucesso."
  end

def solicitar_exclusao
  @participant = Participant.find(params[:id])

  SolicitacaoParticipante.create!(
    participant: @participant,
    motivo: params[:motivo],
    status: :pendente,
  )

  # se o próprio usuário solicitou, derruba ele agora
  if current_user.participant_id == @participant.id
    sign_out(current_user)
    redirect_to new_user_session_path, notice: "Solicitação criada. Seu acesso foi suspenso até aprovação."
  else
    redirect_to participants_path, notice: "Solicitação de exclusão criada. Aguarde aprovação."
  end
end


  # app/controllers/participants_controller.rb
  def por_empresa
    grupo = GrupoEmpresa.find(params[:id])
    participantes = grupo.participants.includes(:user).order(:name)

    participantes_com_usuario = participantes.select { |p| p.user.present? }
    selecionado_id = if participantes_com_usuario.any? { |p| p.id == current_user.participant_id }
        current_user.participant_id
      else
        participantes_com_usuario.first&.id
      end

    render json: {
             participantes: participantes.map do |p|
               {
                 id: p.id,
                 name: p.name,
                 tem_usuario: p.user.present?,
               }
             end,
             selecionado_id: selecionado_id,
           }
  end

  def aprovar_exclusao
    @participant = Participant.find(params[:id])
    solicitacao = @participant.solicitacao_exclusao_pendente
    if solicitacao
      solicitacao.update!(status: "aprovado")
      @participant.update!(excluido: true)
      redirect_to participants_path(tab: "pendentes"), notice: "Exclusão aprovada e participante removido!"
    else
      redirect_to participants_path(tab: "pendentes"), alert: "Solicitação não encontrada."
    end
  end

  def reprovar_exclusao
    @participant = Participant.find(params[:id])
    solicitacao = @participant.solicitacao_exclusao_pendente

    if solicitacao
      novo_status = current_user.client? ? "cancelado" : "reprovado" # precisa existir no enum/tabela
      solicitacao.update!(status: novo_status)
      @participant.update!(excluido: false)
      msg = current_user.client? ? "Solicitação cancelada." : "Solicitação reprovada."
      redirect_to participants_path(tab: "pendentes"), notice: msg
    else
      redirect_to participants_path(tab: "pendentes"), alert: "Solicitação não encontrada."
    end
  end

  before_action :kick_blocked_user

def kick_blocked_user
  return unless user_signed_in?

  if current_user.blocked_access?
    sign_out(current_user)
    redirect_to new_user_session_path, alert: "Seu acesso foi desativado."
  end
end

def block_access
  participant = Participant.find(params[:id])
  user = participant.user

  if user.nil?
    redirect_back fallback_location: participants_path, alert: "Este participante não possui usuário."
    return
  end

  if user.id == current_user.id
    redirect_back fallback_location: participants_path, alert: "Você não pode bloquear a si mesmo."
    return
  end

  user.update!(blocked: true)
  redirect_back fallback_location: participants_path, notice: "Acesso bloqueado com sucesso."
end

def unblock_access
  participant = Participant.find(params[:id])
  user = participant.user

  if user.nil?
    redirect_back fallback_location: participants_path, alert: "Este participante não possui usuário."
    return
  end

  user.update!(blocked: false)
  redirect_back fallback_location: participants_path, notice: "Acesso desbloqueado com sucesso."
end

  private

  def require_admin_or_operador!
  unless current_user.admin? || current_user.operador?
    redirect_back fallback_location: participants_path, alert: "Sem permissão."
  end
end

  def scoped_participants
    super # ← chama o scoped_participants do ApplicationController
          # que já considera admin e operador como tendo acesso a tudo
          # e restringe clientes
  end

  def participant_params
    params.require(:participant).permit(:name, :email, :cpf, :telefone, :photo, :photo_base64, :grupo_empresa_id, :sub_grupo_empresa_id)
  end
end
