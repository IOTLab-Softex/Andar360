class SettingsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_admin!
before_action :set_setting, only: [:edit, :update, :test_mail, :generate_vapid]

def show; end

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

def generate_vapid
  require "openssl"
  require "base64"

  ec = OpenSSL::PKey::EC.generate("prime256v1")
  pub  = ec.public_key.to_octet_string(:uncompressed)
  priv = ec.private_key.to_s(2).rjust(32, "\x00")

  vapid_public  = Base64.urlsafe_encode64(pub,  padding: false)
  vapid_private = Base64.urlsafe_encode64(priv, padding: false)

  subject = params.dig(:setting, :vapid_subject).presence ||
          @setting.vapid_subject.presence ||
          "mailto:suporte@seusite.com"

@setting.update!(
  vapid_public_key:  vapid_public,
  vapid_private_key: vapid_private,
  vapid_subject:     subject
)


  redirect_to edit_setting_path(@setting), notice: "Chaves VAPID geradas com sucesso."
rescue => e
  redirect_to edit_setting_path(@setting), alert: "Falha ao gerar VAPID: #{e.class} - #{e.message}"
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
      :smtp_authentication, :smtp_enable_starttls_auto,
      :password_recovery_test_mode, :password_recovery_test_host, :password_recovery_live_host,
      :password_recovery_link_path, :password_recovery_expiration_minutes, :password_recovery_expiration_unit,
      :password_recovery_email_subject, :password_recovery_email_html,
      :require_room_rules_ack, :room_rules,
      :vapid_public_key, :vapid_private_key, :vapid_subject,
      :camera_min_ratio, :camera_max_ratio, :camera_score_threshold, :camera_good_score,
      :camera_min_zoom, :camera_max_zoom, :camera_zoom_width_factor, :camera_zoom_height_factor,
      :camera_blur_strength, :camera_blur_saturation, :camera_focus_inner_radius, :camera_focus_outer_radius,
      :camera_auto_capture_enabled, :camera_mesh_style
    )
  end
end
