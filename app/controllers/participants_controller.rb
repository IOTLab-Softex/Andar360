class ParticipantsController < ApplicationController
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
    tab = params[:tab] || "ativos"

    case tab
    when "aprovacoes"
      scope = FormularioCadastro.where(status: "pendente")
      if params[:grupo_empresa_id].present? && (current_user.admin? || current_user.operador?)
        scope = scope.where(grupo_empresa_id: params[:grupo_empresa_id])
      elsif current_user.client? && current_user.participant&.grupo_empresa_id.present?
        scope = scope.where(grupo_empresa_id: current_user.participant.grupo_empresa_id)
      else
        scope = scope.none if current_user.client?
      end

      @formularios_pendentes = scope.order(created_at: :desc)
      @participants = Participant.none
    when "reprovados"
      scope = FormularioCadastro.where(status: "reprovado")
      if params[:grupo_empresa_id].present? && (current_user.admin? || current_user.operador?)
        scope = scope.where(grupo_empresa_id: params[:grupo_empresa_id])
      elsif current_user.client? && current_user.participant&.grupo_empresa_id.present?
        scope = scope.where(grupo_empresa_id: current_user.participant.grupo_empresa_id)
      else
        scope = scope.none if current_user.client?
      end

      @formularios_reprovados = scope.order(created_at: :desc)
      @participants = Participant.none
    else
      # 🔒 SEMPRE parte do escopo centralizado
      @participants = scoped_participants

      # abas
      case tab
      when "ativos"
        @participants = @participants.where("excluido = ? OR excluido IS NULL", false)
      when "excluidos"
        @participants = @participants.where(excluido: true)
      when "pendentes"
        ids = SolicitacaoParticipante.where(status: "pendente").pluck(:participant_id)
        @participants = @participants.where(id: ids)
      end

      # filtros extras (sempre em cima do escopo)
      if params[:solicitacao_status].present?
        ids = SolicitacaoParticipante.where(status: params[:solicitacao_status]).pluck(:participant_id)
        @participants = @participants.where(id: ids)
      end

      if params[:grupo_empresa_id].present? && (current_user.admin? || current_user.operador?)
        @participants = @participants.where(grupo_empresa_id: params[:grupo_empresa_id])
      end

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
      motivo: params[:motivo], # pode ser nil ou coletado em modal/form
      status: :pendente,
    )
    redirect_to participants_path, notice: "Solicitação de exclusão criada. Aguarde aprovação."
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

  private

  def scoped_participants
    super # ← chama o scoped_participants do ApplicationController
          # que já considera admin e operador como tendo acesso a tudo
          # e restringe clientes
  end

  def participant_params
    params.require(:participant).permit(:name, :email, :cpf, :telefone, :photo, :photo_base64, :grupo_empresa_id, :sub_grupo_empresa_id)
  end
end
