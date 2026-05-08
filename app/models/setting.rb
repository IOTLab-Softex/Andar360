require "cgi"

class Setting < ApplicationRecord
  has_rich_text :room_rules

  PASSWORD_RECOVERY_DEFAULT_SUBJECT = "Recuperacao de senha - Andar360".freeze
  PASSWORD_RECOVERY_DEFAULT_TEST_HOST = "localhost:3000".freeze
  PASSWORD_RECOVERY_DEFAULT_LIVE_HOST = "softexsrs.ddns.net".freeze
  PASSWORD_RECOVERY_DEFAULT_PATH = "/users/password/edit".freeze
  PASSWORD_RECOVERY_DEFAULT_EXPIRATION_MINUTES = 360
  PASSWORD_RECOVERY_DEFAULT_EXPIRATION_UNIT = "minutes".freeze
  PASSWORD_RECOVERY_DEFAULT_HTML = <<~HTML.freeze
    <div style="margin:0;padding:0;background:#eef2f7;">
      <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#eef2f7;padding:32px 16px;">
        <tbody>
          <tr>
            <td align="center">
              <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:680px;background:#ffffff;border-radius:22px;overflow:hidden;border:1px solid #e5e7eb;box-shadow:0 24px 60px rgba(15,23,42,0.12);">
                <tbody>
                  <tr>
                    <td style="background:#dcd8ea;padding:34px 34px 38px;">
                      <img src="https://moodle.aponti.org.br/pluginfile.php/1/theme_moove/logo/1775435818/logo%20aponti.png" alt="Logo Aponti" style="display:block;max-width:180px;width:100%;height:auto;margin:0 0 22px;">

                      <div style="font-family:Arial,sans-serif;font-size:12px;letter-spacing:2px;text-transform:uppercase;color:#120235;font-weight:700;margin-bottom:12px;">
                        Recuperacao de acesso
                      </div>

                      <h1 style="margin:0;font-family:Arial,sans-serif;font-size:36px;line-height:1.15;color:#2f1668;font-weight:800;">
                        Recuperacao de senha
                      </h1>

                      <p style="margin:16px 0 0;font-family:Arial,sans-serif;font-size:16px;line-height:1.8;color:#1f2937;max-width:520px;">
                        Recebemos uma solicitacao para redefinir o acesso da sua conta com seguranca.
                      </p>
                    </td>
                  </tr>

                  <tr>
                    <td style="padding:38px 34px 34px;">
                      <p style="margin:0 0 18px;font-family:Arial,sans-serif;font-size:18px;line-height:1.7;color:#111827;">
                        Ola, <strong>{{user_name}}</strong>.
                      </p>

                      <p style="margin:0 0 20px;font-family:Arial,sans-serif;font-size:16px;line-height:1.9;color:#374151;">
                        Para continuar com a redefinicao da sua senha, clique no botao abaixo. Esse link foi gerado de forma segura para a sua conta.
                      </p>

                      <table role="presentation" cellpadding="0" cellspacing="0" style="margin:28px 0 26px;">
                        <tbody>
                          <tr>
                            <td align="center" style="border-radius:14px;background:linear-gradient(135deg,#6d28d9 0%,#7c3aed 50%,#8b5cf6 100%);box-shadow:0 14px 30px rgba(124,58,237,0.24);">
                              <a href="{{reset_url}}" style="display:inline-block;padding:16px 30px;font-family:Arial,sans-serif;font-size:16px;font-weight:700;color:#ffffff;text-decoration:none;border-radius:14px;">
                                Redefinir minha senha
                              </a>
                            </td>
                          </tr>
                        </tbody>
                      </table>

                      <div style="margin:0 0 22px;padding:20px 20px;background:#f8fafc;border:1px solid #e5e7eb;border-radius:16px;">
                        <p style="margin:0 0 10px;font-family:Arial,sans-serif;font-size:15px;font-weight:700;color:#111827;">
                          Se o botao nao abrir:
                        </p>
                        <p style="margin:0;font-family:Arial,sans-serif;font-size:13px;line-height:1.8;color:#4b5563;word-break:break-all;">
                          <a href="{{reset_url}}" style="color:#6d28d9;text-decoration:none;">{{reset_url}}</a>
                        </p>
                      </div>

                      <div style="margin:0 0 24px;padding:20px 20px;background:linear-gradient(180deg,#f8fafc 0%,#f3f4f6 100%);border:1px solid #e5e7eb;border-radius:16px;">
                        <p style="margin:0 0 12px;font-family:Arial,sans-serif;font-size:15px;font-weight:700;color:#111827;">
                          Importante
                        </p>
                        <ul style="margin:0;padding-left:20px;font-family:Arial,sans-serif;font-size:14px;line-height:1.9;color:#4b5563;">
                          <li>Use este link apenas se voce solicitou a recuperacao.</li>
                          <li>Nao compartilhe este e-mail com outras pessoas.</li>
                          <li>Se voce nao reconhece esta solicitacao, ignore esta mensagem.</li>
                        </ul>
                      </div>

                      <p style="margin:0;font-family:Arial,sans-serif;font-size:14px;line-height:1.8;color:#6b7280;">
                        Conta vinculada: <strong style="color:#374151;">{{user_email}}</strong>
                      </p>
                    </td>
                  </tr>

                  <tr>
                    <td style="padding:24px 34px;background:#111827;">
                      <p style="margin:0 0 8px;font-family:Arial,sans-serif;font-size:13px;line-height:1.8;color:#d1d5db;">
                        Este e-mail foi enviado automaticamente pelo sistema <strong style="color:#ffffff;">{{app_name}}</strong>.
                      </p>
                      <p style="margin:0;font-family:Arial,sans-serif;font-size:12px;line-height:1.8;color:#9ca3af;">
                        Ambiente configurado em: {{recovery_host}}
                      </p>
                      <p style="margin:8px 0 0;font-family:Arial,sans-serif;font-size:12px;line-height:1.8;color:#9ca3af;">
                        Este link expira em {{reset_expiration}}.
                      </p>
                    </td>
                  </tr>
                </tbody>
              </table>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  HTML

  CAMERA_TUNING_DEFAULTS = {
    minRatio: 0.30,
    maxRatio: 0.70,
    scoreThreshold: 0.50,
    goodScore: 0.60,
    minZoom: 1.12,
    maxZoom: 1.82,
    zoomWidthFactor: 1.02,
    zoomHeightFactor: 0.94,
    blurStrength: 3,
    blurSaturation: 1.00,
    focusInnerRadius: 67,
    focusOuterRadius: 92,
    autoCaptureEnabled: true,
    meshStyle: "biometric"
  }.freeze

  def self.instance
  first_or_create!
end

    def self.get(key)
  find_by(key: key)&.value
end


# app/models/setting.rb
after_commit :reload_schedulers, on: [:update]

  def require_room_rules_ack?
    require_room_rules_ack == true
  end
  
def reload_schedulers
  SchedulerManager.reload_all
end



  # Defaults elegantes (evita nils)
  def smtp_address_or_default
    smtp_address.presence || "smtp.gmail.com"
  end

  def smtp_port_or_default
    (smtp_port.presence || 587).to_i
  end

  def smtp_authentication_or_default
    (smtp_authentication.presence || "plain").to_sym
  end

  def smtp_enable_starttls_auto_or_default
    smtp_enable_starttls_auto.nil? ? true : smtp_enable_starttls_auto
  end

  def from_email_or_default
    smtp_from_email.presence || smtp_username.presence || "no-reply@localhost"
  end

  def reply_to_or_default
    smtp_reply_to.presence
  end

  def password_recovery_test_mode?
    password_recovery_test_mode.nil? ? true : password_recovery_test_mode
  end

  def login_weather_card_enabled?
    login_weather_card_enabled == true
  end

  def login_weather_city_or_default
    login_weather_city.presence || "Recife"
  end

  def login_weather_latitude_or_default
    (login_weather_latitude.presence || -8.047562).to_f
  end

  def login_weather_longitude_or_default
    (login_weather_longitude.presence || -34.877003).to_f
  end

  def password_recovery_test_host_or_default
    password_recovery_test_host.presence || PASSWORD_RECOVERY_DEFAULT_TEST_HOST
  end

  def password_recovery_live_host_or_default
    password_recovery_live_host.presence || PASSWORD_RECOVERY_DEFAULT_LIVE_HOST
  end

  def password_recovery_link_path_or_default
    normalized_path(password_recovery_link_path.presence || PASSWORD_RECOVERY_DEFAULT_PATH)
  end

  def password_recovery_expiration_minutes_or_default
    value = password_recovery_expiration_minutes.presence || PASSWORD_RECOVERY_DEFAULT_EXPIRATION_MINUTES
    [value.to_i, 1].max
  end

  def password_recovery_expiration_unit_or_default
    value = password_recovery_expiration_unit.presence || PASSWORD_RECOVERY_DEFAULT_EXPIRATION_UNIT
    %w[seconds minutes].include?(value) ? value : PASSWORD_RECOVERY_DEFAULT_EXPIRATION_UNIT
  end

  def password_recovery_reset_within
    value = password_recovery_expiration_minutes_or_default
    password_recovery_expiration_unit_or_default == "seconds" ? value.seconds : value.minutes
  end

  def password_recovery_email_subject_or_default
    password_recovery_email_subject.presence || PASSWORD_RECOVERY_DEFAULT_SUBJECT
  end

  def password_recovery_email_html_or_default
    password_recovery_email_html.presence || PASSWORD_RECOVERY_DEFAULT_HTML
  end

  def password_recovery_base_url
    raw_host = password_recovery_test_mode? ? password_recovery_test_host_or_default : password_recovery_live_host_or_default
    normalized_host(raw_host)
  end

  def password_recovery_url(token)
    base_url = password_recovery_base_url
    path = password_recovery_link_path_or_default
    separator = path.include?("?") ? "&" : "?"
    "#{base_url}#{path}#{separator}reset_password_token=#{CGI.escape(token.to_s)}"
  end

  def password_recovery_email_html_for(user, token)
    html = password_recovery_email_html_or_default.dup
    reset_url = password_recovery_url(token)
    user_name = user.try(:name).presence || user.try(:participant).try(:name).presence || user.email.to_s
    replacements = {
      "{{reset_url}}" => reset_url,
      "{{user_email}}" => user.email.to_s,
      "{{user_name}}" => user_name,
      "{{app_name}}" => "Andar360",
      "{{recovery_host}}" => password_recovery_base_url,
      "{{reset_expiration}}" => password_recovery_expiration_label
    }

    replacements.each do |placeholder, value|
      html.gsub!(placeholder, value.to_s)
    end

    html
  end

  def password_recovery_expiration_label
    value = password_recovery_expiration_minutes_or_default
    if password_recovery_expiration_unit_or_default == "seconds"
      return "1 segundo" if value == 1
      return "#{value} segundos"
    end

    minutes = value
    return "1 minuto" if minutes == 1
    return "#{minutes} minutos" if minutes < 60

    hours = minutes / 60
    remainder = minutes % 60
    return "#{hours} hora" if hours == 1 && remainder.zero?
    return "#{hours} horas" if remainder.zero?

    "#{hours}h #{remainder}min"
  end

  def camera_tuning_config
    CAMERA_TUNING_DEFAULTS.merge(
      minRatio: camera_min_ratio.presence || CAMERA_TUNING_DEFAULTS[:minRatio],
      maxRatio: camera_max_ratio.presence || CAMERA_TUNING_DEFAULTS[:maxRatio],
      scoreThreshold: camera_score_threshold.presence || CAMERA_TUNING_DEFAULTS[:scoreThreshold],
      goodScore: camera_good_score.presence || CAMERA_TUNING_DEFAULTS[:goodScore],
      minZoom: camera_min_zoom.presence || CAMERA_TUNING_DEFAULTS[:minZoom],
      maxZoom: camera_max_zoom.presence || CAMERA_TUNING_DEFAULTS[:maxZoom],
      zoomWidthFactor: camera_zoom_width_factor.presence || CAMERA_TUNING_DEFAULTS[:zoomWidthFactor],
      zoomHeightFactor: camera_zoom_height_factor.presence || CAMERA_TUNING_DEFAULTS[:zoomHeightFactor],
      blurStrength: camera_blur_strength.presence || CAMERA_TUNING_DEFAULTS[:blurStrength],
      blurSaturation: camera_blur_saturation.presence || CAMERA_TUNING_DEFAULTS[:blurSaturation],
      focusInnerRadius: camera_focus_inner_radius.presence || CAMERA_TUNING_DEFAULTS[:focusInnerRadius],
      focusOuterRadius: camera_focus_outer_radius.presence || CAMERA_TUNING_DEFAULTS[:focusOuterRadius],
      autoCaptureEnabled: camera_auto_capture_enabled.nil? ? CAMERA_TUNING_DEFAULTS[:autoCaptureEnabled] : camera_auto_capture_enabled,
      meshStyle: camera_mesh_style.presence || CAMERA_TUNING_DEFAULTS[:meshStyle]
    )
  end

  private

  def normalized_path(path)
    value = path.to_s.strip
    return PASSWORD_RECOVERY_DEFAULT_PATH if value.blank?

    value.start_with?("/") ? value : "/#{value}"
  end

  def normalized_host(host)
    value = host.to_s.strip.sub(%r{/+\z}, "")
    return "http://#{PASSWORD_RECOVERY_DEFAULT_TEST_HOST}" if value.blank?
    return value if value.match?(/\Ahttps?:\/\//i)

    scheme = value.match?(/\Alocalhost(?::\d+)?\z/i) || value.match?(/\A\d{1,3}(?:\.\d{1,3}){3}(?::\d+)?\z/) ? "http" : "https"
    "#{scheme}://#{value}"
  end
end
