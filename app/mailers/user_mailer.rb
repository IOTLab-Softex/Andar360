class UserMailer < Devise::Mailer
  helper :application
  include Devise::Controllers::UrlHelpers

  default template_path: "user_mailer"

  def reset_password_instructions(record, token, opts = {})
    @setting = Setting.instance
    @resource = record
    @token = token
    @reset_url = @setting.password_recovery_url(token)
    @password_recovery_html = @setting.password_recovery_email_html_for(record, token)
    opts[:subject] = @setting.password_recovery_email_subject_or_default

    devise_mail(record, :reset_password_instructions, opts)
  end
end
