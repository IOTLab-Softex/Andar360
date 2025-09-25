class TestMailer < ApplicationMailer
  def ping
    @when = Time.current
    mail(to: params[:to], subject: "Teste SMTP OK - #{Rails.env.upcase}")
  end
end
