class SettingsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_admin!
  before_action :set_setting, only: [:edit, :update, :test_mail]

  def index
    setting = Setting.first_or_create!
    redirect_to edit_setting_path(setting)
  end

  def edit; end

  def update
  if params[:setting].present? && params[:setting][:smtp_password].blank?
    params[:setting].delete(:smtp_password)
  end

  if @setting.update(setting_params)
    MailSettings.apply!
    redirect_to edit_setting_path(@setting), notice: "Configurações atualizadas"
  else
    render :edit, status: :unprocessable_entity
  end
end


def test_mail
  MailSettings.apply!
  to = params[:test_to].presence ||
       current_user&.email.presence ||
       @setting.smtp_username ||
       @setting.smtp_from_email

  TestMailer.with(to: to).ping.deliver_now
  redirect_to edit_setting_path(@setting), notice: "E-mail de teste enviado para #{to}."
rescue => e
  redirect_to edit_setting_path(@setting), alert: "Falha: #{e.class} - #{e.message}"
end


  private

  def set_setting
    @setting = Setting.first || Setting.create!
  end

  def authorize_admin!
    redirect_to root_path, alert: "Acesso não autorizado." unless current_user&.admin?
  end

  def setting_params
    params.require(:setting).permit(
      :backup_dir,
      :tempo_checagem_acesso, :tempo_checagem_acesso_unidade,
      :tempo_checagem_reservas, :tempo_checagem_reservas_unidade,
      :limite_horas_turno_reservas_manha, :limite_horas_turno_reservas_tarde, :limite_horas_turno_reservas_noite,
      :tempo_verificacao_online, :tempo_verificacao_online_unidade,
      :horario_rotina_importacao,
      :smtp_from_email, :smtp_reply_to,
      :smtp_address, :smtp_port, :smtp_domain,
      :smtp_username, :smtp_password,
      :smtp_authentication, :smtp_enable_starttls_auto,:require_room_rules_ack, :room_rules
    )
  end
end
