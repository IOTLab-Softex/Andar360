# frozen_string_literal: true
class MailSettings
  def self.apply!
    s = Setting.first
    return unless s

    ActionMailer::Base.smtp_settings = {
      address:              s.smtp_address_or_default,
      port:                 s.smtp_port_or_default,
      domain:               s.smtp_domain.presence || "gmail.com",
      user_name:            s.smtp_username.presence,
      password:             s.smtp_password.presence,
      authentication:       s.smtp_authentication_or_default,
      enable_starttls_auto: s.smtp_enable_starttls_auto_or_default
    }.compact

    # from/reply_to dinâmicos (cada e-mail herdará do ApplicationMailer)
    ApplicationMailer.default from: s.from_email_or_default, reply_to: s.reply_to_or_default
  end
end
