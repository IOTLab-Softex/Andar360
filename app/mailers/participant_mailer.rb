class ParticipantMailer < ApplicationMailer
  default from: "no-reply@sua-empresa.com"
  # se você tiver algo como `default to: -> { @participant&.email }`, remova ou deixe nil
  # default to: nil

def participant_created
  @participant = params[:participant]
  @formulario  = params[:formulario]
  @form = @formulario # <- opcional, só para compatibilidade
  mail(to: @participant.email, subject: "Seu cadastro foi recebido")
end




  def formulario_received
    @formulario = params[:formulario]
    mail(to: params[:to], subject: "Novo pré-cadastro recebido: #{@formulario.nome} (#{@formulario.cpf})")
  end

  def formulario_approved
    @formulario = params[:formulario]
    mail(to: params[:to], subject: "Pré-cadastro aprovado: #{@formulario.nome}")
  end

  def formulario_rejected
    @formulario = params[:formulario]
    @motivo     = params[:motivo].presence || @formulario.motivo_reprovacao
    mail(to: params[:to], subject: "Pré-cadastro reprovado: #{@formulario.nome}")
  end

  def notify_company
  @participant = params[:participant]
  @formulario  = params[:formulario]
  recipients   = Array(params[:to]).map { |e| e.to_s.strip.downcase }.uniq
  recipients -= [@participant.email.to_s.strip.downcase] # evita mandar pro participante

  return if recipients.empty?

  mail(
    to: recipients,
    subject: "Novo cadastro recebido: #{@participant.name} (#{@participant.cpf})"
  )
end


end
