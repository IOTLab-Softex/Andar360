# app/controllers/formulario_cadastros_controller.rb
require "base64"
require "stringio"

class FormularioCadastrosController < ApplicationController
  before_action :set_formulario_cadastro, only: %i[
    show edit update destroy approve reject reenviar_para_aprovacao
  ]
  before_action :authorize_admin_or_operator!, only: %i[ approve reject bulk_approve bulk_reject ]
  before_action :authorize_resubmitter!,      only: %i[ reenviar_para_aprovacao ]

  def index
    @formulario_cadastros = FormularioCadastro.all
  end

  def show; end

  def new
    @formulario_cadastro = FormularioCadastro.new
    @formulario_cadastro.grupo_empresa_id = default_grupo_empresa_id
  end

  def edit; end

  # 👉 AGORA NÃO CRIA PARTICIPANT AQUI
  def create
    arruma_campos_checkboxes
    @formulario_cadastro = FormularioCadastro.new(formulario_cadastro_params)
    @formulario_cadastro.grupo_empresa_id = current_user.participant&.grupo_empresa_id if current_user&.client?
    attach_foto_base64(@formulario_cadastro)

    # Bloqueia se já existe Participant OU já existe pré-cadastro pendente do mesmo CPF
    if Participant.exists?(cpf: @formulario_cadastro.cpf) ||
       FormularioCadastro.where(cpf: @formulario_cadastro.cpf, status: "pendente").exists?
      @formulario_cadastro.errors.add(:cpf, "já está cadastrado ou possui pré-cadastro pendente!")
      flash.now[:alert] = "CPF já cadastrado ou pendente!"
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @formulario_cadastro.errors, status: :unprocessable_entity }
      end
      return
    end

    respond_to do |format|
      if @formulario_cadastro.save
        # Email somente ao usuário logado, se da mesma empresa
        same_company = current_user&.participant&.grupo_empresa_id == @formulario_cadastro.grupo_empresa_id
        if same_company && current_user.email.present?
          MailSettings.apply! rescue nil
          ParticipantMailer.with(
            formulario: @formulario_cadastro,
            to: current_user.email
          ).formulario_received.deliver_now
        end

      format.html do
        redirect_to new_formulario_cadastro_path(grupo_empresa_id: @formulario_cadastro.grupo_empresa_id),
                    notice: "Pré-cadastro criado e aguardando aprovação."
      end

      # (opcional) ajuste o JSON se você usa API
      format.json do
        render json: { ok: true, redirect_to: new_formulario_cadastro_path }, status: :created
      end
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @formulario_cadastro.errors, status: :unprocessable_entity }
      end
    end
  end

def update
  arruma_campos_checkboxes
  attach_foto_base64(@formulario_cadastro)

  respond_to do |format|
    if @formulario_cadastro.update(formulario_cadastro_params)
      # ✅ depois de atualizar, volta para /participants?tab=reprovados
      format.html { redirect_to participants_path(tab: 'reprovados'), notice: "Pré-cadastro atualizado." }
      format.json { render :show, status: :ok, location: @formulario_cadastro }
    else
      format.html { render :edit, status: :unprocessable_entity }
      format.json { render json: @formulario_cadastro.errors, status: :unprocessable_entity }
    end
  end
end


def destroy
  @formulario_cadastro.destroy!
  redirect_back fallback_location: participants_path(tab: 'reprovados'),
                status: :see_other,
                notice: "Pré-cadastro removido."
end


  # 👉 Aprovar = criar Participant e marcar como aprovado
  def approve
    if Participant.exists?(cpf: @formulario_cadastro.cpf)
      redirect_to participants_path(tab: 'aprovacoes'), alert: "Já existe participante com este CPF."
      return
    end

    participant = Participant.create!(
      name:  @formulario_cadastro.nome,
      email: @formulario_cadastro.email,
      cpf:   @formulario_cadastro.cpf,
      telefone: @formulario_cadastro.telefone,
      grupo_empresa_id: @formulario_cadastro.grupo_empresa_id
    )
    participant.photo.attach(@formulario_cadastro.foto.blob) if @formulario_cadastro.foto.attached?

    @formulario_cadastro.update!(
      status: "aprovado",
      aprovado_por_id: current_user.id,
      aprovado_em: Time.current
    )

    # 🔔 Enviar e-mail aos USERS da empresa (role: client)
    notify_company_clients!(@formulario_cadastro, :formulario_approved)

    redirect_to participants_path(tab: 'ativos'), notice: "Pré-cadastro aprovado e participante criado."
  end

  # 👉 Reprovar = não cria Participant e marca como reprovado
  def reject
    motivo = params[:motivo].presence || "Sem motivo informado"

    @formulario_cadastro.update!(
      status: "reprovado",
      reprovado_por_id: current_user.id,
      reprovado_em: Time.current,
      motivo_reprovacao: motivo
    )

    # 🔔 Enviar e-mail aos USERS da empresa (role: client)
    notify_company_clients!(@formulario_cadastro, :formulario_rejected, motivo: motivo)

    redirect_to participants_path(tab: 'aprovacoes'), notice: "Pré-cadastro reprovado."
  end

  # FormularioCadastrosController
def bulk_approve
    ids = Array(params[:ids]).map(&:to_i)
    aprovados = 0

    FormularioCadastro.where(id: ids, status: "pendente").find_each do |f|
      next if Participant.exists?(cpf: f.cpf)

      p = Participant.create!(
        name:  f.nome, email: f.email, cpf: f.cpf,
        telefone: f.telefone, grupo_empresa_id: f.grupo_empresa_id
      )
      p.photo.attach(f.foto.blob) if f.foto.attached?

      f.update!(status: "aprovado", aprovado_por_id: current_user.id, aprovado_em: Time.current)
      aprovados += 1

      # 🔔 Notifica client(s) da empresa
      notify_company_clients!(f, :formulario_approved)
    end

    redirect_to participants_path(tab: 'aprovacoes'), notice: "#{aprovados} aprovado(s)."
  end

def bulk_reject
    ids    = Array(params[:ids]).map(&:to_i)
    motivo = params[:motivo].presence || "Reprovado em massa"
    reprovados = 0

    FormularioCadastro.where(id: ids, status: "pendente").find_each do |f|
      f.update!(
        status: "reprovado",
        motivo_reprovacao: motivo,
        reprovado_por_id: current_user.id,
        reprovado_em: Time.current
      )
      reprovados += 1

      # 🔔 Notifica client(s) da empresa
      notify_company_clients!(f, :formulario_rejected, motivo: motivo)
    end

    redirect_to participants_path(tab: 'aprovacoes'), notice: "#{reprovados} reprovado(s)."
  end


  def arruma_campos_checkboxes
    if params[:formulario_cadastro][:horario_trabalho].is_a?(Array)
      params[:formulario_cadastro][:horario_trabalho] = params[:formulario_cadastro][:horario_trabalho].reject(&:blank?).join(",")
    end
    if params[:formulario_cadastro][:dias_trabalho].is_a?(Array)
      params[:formulario_cadastro][:dias_trabalho] = params[:formulario_cadastro][:dias_trabalho].reject(&:blank?).join(",")
    end
  end

  def reenviar_para_aprovacao
  unless @formulario_cadastro
    redirect_back fallback_location: participants_path(tab: 'reprovados'),
                  alert: "Pré-cadastro não encontrado."
    return
  end

  if @formulario_cadastro.status != "reprovado"
    redirect_back fallback_location: participants_path(tab: 'reprovados'),
                  alert: "Somente cadastros reprovados podem ser reenviados."
    return
  end

  @formulario_cadastro.update!(
    status: "pendente",
    motivo_reprovacao: nil,
    reprovado_por_id: nil,
    reprovado_em: nil
  )

  redirect_to participants_path(tab: 'aprovacoes'),
              notice: "Pré-cadastro reenviado para aprovação."
end


def authorize_resubmitter!
  return if current_user&.admin? || current_user&.operador?
  mesma_empresa = current_user&.participant&.grupo_empresa_id == @formulario_cadastro.grupo_empresa_id
  redirect_back fallback_location: participants_path, alert: "Acesso negado." unless mesma_empresa
end

  private

  def company_client_emails(grupo_empresa_id)
    User.joins(:participant)
        .where(role: :client)
        .where(participants: { grupo_empresa_id: grupo_empresa_id })
        .where.not(email: [nil, ""])
        .distinct
        .pluck(:email)
  end
  
   def notify_company_clients!(formulario, template, **kwargs)
    emails = company_client_emails(formulario.grupo_empresa_id)
    return 0 if emails.blank?

    MailSettings.apply! rescue nil
    emails.each do |email|
      ParticipantMailer.with({ formulario: formulario, to: email }.merge(kwargs))
                      .public_send(template)
                      .deliver_now
    end
    emails.size
  end
  

  def set_formulario_cadastro
    @formulario_cadastro = FormularioCadastro.find(params[:id])
  end

  def default_grupo_empresa_id
    return current_user.participant&.grupo_empresa_id if current_user&.client?

    params[:grupo_empresa_id].presence
  end

  def formulario_cadastro_params
    params.require(:formulario_cadastro).permit(
      :nome, :cpf, :telefone, :email, :cargo,
      :horario_trabalho, :dias_trabalho, :foto, :foto_base64,
      :concorda_termos, :observacao, :grupo_empresa_id
    )
  end

  def attach_foto_base64(record)
    data = record.foto_base64.presence || params.dig(:formulario_cadastro, :foto_base64).presence
    return if data.blank?
    content_type = data[%r{\Adata:(.*?);base64,}i, 1] || "image/png"
    raw = data.sub(%r{\Adata:.*;base64,}i, "")
    io = StringIO.new(Base64.decode64(raw))
    ext = content_type.split("/").last
    record.foto.attach(io: io, filename: "foto_#{Time.zone.now.to_i}.#{ext}", content_type: content_type)
  end

  def authorize_admin_or_operator!
    unless current_user&.admin? || current_user&.operador?
      redirect_to participants_path, alert: "Acesso negado." and return
    end
  end
end
