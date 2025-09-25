class Setting < ApplicationRecord

    def self.get(key)
  find_by(key: key)&.value
end


# app/models/setting.rb
after_commit :reload_schedulers, on: [:update]

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
    smtp_from_email.presence || smtp_username.presence
  end

  def reply_to_or_default
    smtp_reply_to.presence
  end
end
