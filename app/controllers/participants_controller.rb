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
        email: @participant.email, # pode ser opcional
        password: senha,
        password_confirmation: senha,
        role: params[:user_role],
        participant_id: @participant.id,
        force_password_change: true
        )
  
        Rails.logger.info "Usuário criado: #{user.email} - Senha: #{senha}"
      end
  
      redirect_to participants_path, notice: "Participante criado com sucesso!"
    else
      render action: :new, status: :unprocessable_entity

    end
  end

  def edit
    @participant = Participant.find(params[:id])
  end

  def update
  @participant = Participant.find(params[:id])
  if @participant.update(participant_params)
    if params[:criar_usuario] == "1"
      # ✅ Criar ou atualizar usuário
      senha = params[:manter_senha] == "1" ? nil : (params[:senha_gerada] || SecureRandom.hex(4))

      if @participant.user.present?
        # Atualiza usuário existente
        user = @participant.user
        user.role = params[:user_role] if params[:user_role].present?

        if senha.present?
          user.password = senha
          user.password_confirmation = senha
          user.force_password_change = true
          Rails.logger.info "Senha atualizada para #{user.email || user.cpf} - Nova senha: #{senha}"
        elsif user.force_password_change?
          # remove a flag se não for mais necessário
          user.force_password_change = false
        end


        user.save!
      else
        # Cria novo usuário
        user = User.create!(
          cpf: @participant.cpf,
          email: @participant.email,
          password: senha || SecureRandom.hex(4),
          password_confirmation: senha || SecureRandom.hex(4),
          role: params[:user_role],
          participant_id: @participant.id,
          force_password_change: true
        )
        Rails.logger.info "Usuário criado: #{user.email || user.cpf} - Senha: #{senha}"
      end

    elsif params[:criar_usuario] != "1" && @participant.user.present?
      # ❌ Remove usuário existente
      @participant.user.destroy
      Rails.logger.info "Acesso removido para o participante #{@participant.id}"
    end

    redirect_to participants_path, notice: "Participante atualizado com sucesso."
  else
    render :edit, status: :unprocessable_entity
  end
end


  def camera
    render layout: false
  end

  def index
  @participants = scoped_participants

  if params[:grupo_empresa_id].present? && current_user.admin?
    @participants = @participants.where(grupo_empresa_id: params[:grupo_empresa_id])
  end

  if params[:search].present?
    @participants = @participants.where("name ILIKE ? OR cpf ILIKE ?", "%#{params[:search]}%", "%#{params[:search]}%")
  end

  if params[:sub_grupo_empresa_id].present?
    @participants = @participants.where(sub_grupo_empresa_id: params[:sub_grupo_empresa_id])
  end
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


  private

 def participant_params
  params.require(:participant).permit(:name, :email, :cpf, :telefone, :photo, :photo_base64, :grupo_empresa_id, :sub_grupo_empresa_id)
end

  
end
