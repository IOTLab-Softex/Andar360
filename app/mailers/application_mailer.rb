class ApplicationMailer < ActionMailer::Base
 default from: ->(*) { Setting.first&.from_email_or_default },
          reply_to: ->(*) { Setting.first&.reply_to_or_default }
  layout "mailer"
end
