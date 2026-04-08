class PasswordRecoverySupportMailer < ApplicationMailer
  def request_support
    @user = params[:user]
    @support_contact = params[:support_contact]

    mail(
      to: @support_contact,
      subject: "Solicitacao de suporte para recuperacao de senha - #{@user.name.presence || @user.email || @user.cpf}"
    )
  end
end
