require "base64"
require "mini_magick"

class PasswordRecoveriesController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :check_password_change_required

  FACE_VERIFY_SESSION_WINDOW = 10.minutes
  FACE_LOOKUP_SESSION_KEY = "password_recovery_pending_cpf"
  SUPPORT_LOOKUP_SESSION_KEY = "password_recovery_support_pending_cpf"

  def facial_status
    FaceBackend::Service.ensure_started!

    render json: {
      ok: true,
      online: true,
      message: "Serviço de reconhecimento facial online."
    }
  rescue StandardError => e
    render json: {
      ok: false,
      online: false,
      message: e.message.presence || "Serviço de reconhecimento facial indisponível."
    }, status: :service_unavailable
  end

  def facial_lookup
    user = find_user_by_cpf(params[:cpf])
    return render json: { ok: false, message: "CPF não encontrado." }, status: :not_found unless user

    participant = user.participant
    return render json: { ok: false, message: "Usuário sem participante vinculado." }, status: :unprocessable_entity unless participant
    return render json: { ok: false, message: "Usuário sem foto cadastrada para validação facial." }, status: :unprocessable_entity unless participant.photo.attached?

    if user.email.blank?
      return render json: {
        ok: false,
        message: "Este usuário não possui e-mail cadastrado para recuperação segura. Use a opção de suporte.",
        support_only: true
      }, status: :unprocessable_entity
    end

    session[FACE_LOOKUP_SESSION_KEY] = normalized_cpf(params[:cpf])
    session.delete(verified_session_key(normalized_cpf(params[:cpf])))

    photo_dimensions = photo_dimensions_for(participant.photo)

    render json: {
      ok: true,
      cpf: normalized_cpf(params[:cpf]),
      photo_url: view_context.url_for(participant.photo),
      photo_width: photo_dimensions[:width],
      photo_height: photo_dimensions[:height],
      message: "Perfil localizado. Abra a câmera para validação facial segura."
    }
  end

  def support_lookup
    user = find_user_by_cpf(params[:cpf])
    return render json: { ok: false, message: "CPF não encontrado." }, status: :not_found unless user

    session[SUPPORT_LOOKUP_SESSION_KEY] = normalized_cpf(params[:cpf])

    render json: {
      ok: true,
      cpf: normalized_cpf(params[:cpf]),
      message: "CPF confirmado. Agora você já pode solicitar o suporte."
    }
  end

  def facial_verify
    cpf = normalized_cpf(params[:cpf])
    return render json: { ok: false, message: "CPF inválido." }, status: :unprocessable_entity if cpf.blank?
    return render json: { ok: false, message: "Sessão expirada. Informe o CPF novamente." }, status: :unprocessable_entity unless session[FACE_LOOKUP_SESSION_KEY] == cpf

    user = find_user_by_cpf(cpf)
    return render json: { ok: false, message: "CPF não encontrado." }, status: :not_found unless user

    participant = user.participant
    return render json: { ok: false, message: "Usuário sem participante vinculado." }, status: :unprocessable_entity unless participant
    return render json: { ok: false, message: "Usuário sem foto cadastrada para validação facial." }, status: :unprocessable_entity unless participant.photo.attached?

    probe_image_base64 = params[:photo_base64].to_s
    return render json: { ok: false, message: "Nenhuma imagem recebida para validação." }, status: :unprocessable_entity if probe_image_base64.blank?

    reference_image_base64 = Base64.strict_encode64(participant.photo.download)
    comparison = FaceBackend::Client.verify(
      reference_image_base64: reference_image_base64,
      probe_image_base64: probe_image_base64
    )

    if comparison[:matched]
      session[verified_session_key(cpf)] = Time.current.iso8601

      return render json: {
        ok: true,
        matched: true,
        message: "Rosto validado com sucesso.",
        confidence: comparison[:confidence],
        score: comparison[:score],
        distance: comparison[:distance],
        debug: comparison[:debug]
      }
    end

    render json: {
      ok: false,
      matched: false,
      message: comparison[:message].presence || "Não foi possível validar o rosto com segurança.",
      reference_issue: comparison[:message].to_s.include?("foto cadastrada"),
      capture_issue: comparison[:message].to_s.include?("rosto capturado"),
      confidence: comparison[:confidence],
      score: comparison[:score],
      distance: comparison[:distance],
      debug: comparison[:debug]
    }, status: :unprocessable_entity
  rescue FaceBackend::Client::ServiceError => e
    render json: { ok: false, message: e.message, retryable: true }, status: :service_unavailable
  end

  def facial_send_reset
    user = find_user_by_cpf(params[:cpf])
    return render json: { ok: false, message: "CPF não encontrado." }, status: :not_found unless user
    return render json: { ok: false, message: "E-mail não cadastrado para este usuário." }, status: :unprocessable_entity if user.email.blank?
    return render json: { ok: false, message: "Realize novamente a validação facial para continuar." }, status: :unprocessable_entity unless facial_verified_recently?(normalized_cpf(params[:cpf]))

    cooldown_key = "password_recovery_reset_sent_at_#{normalized_cpf(params[:cpf])}"
    last_sent_at = session[cooldown_key]
    if last_sent_at.present? && Time.zone.parse(last_sent_at.to_s) > 1.minute.ago
      return render json: {
        ok: false,
        message: "Já enviamos um link recentemente. Aguarde um minuto para tentar novamente."
      }, status: :too_many_requests
    end

    MailSettings.apply!
    user.send_reset_password_instructions
    session[cooldown_key] = Time.current.iso8601

    render json: {
      ok: true,
      message: "Enviamos um link seguro de redefinição para #{masked_email(user.email)}."
    }
  rescue Errno::ECONNREFUSED, SocketError, IOError, SystemCallError
    render json: {
      ok: false,
      message: "Não foi possível conectar ao servidor de e-mail configurado. Revise as configurações SMTP."
    }, status: :service_unavailable
  rescue Net::SMTPAuthenticationError, Net::SMTPServerBusy, Net::SMTPSyntaxError, Net::SMTPFatalError, Net::SMTPUnknownError => e
    render json: {
      ok: false,
      message: "Falha no envio do e-mail de recuperação: #{e.message}"
    }, status: :unprocessable_entity
  end

  def support_request
    cpf = normalized_cpf(params[:cpf])
    return render json: { ok: false, message: "CPF inválido." }, status: :unprocessable_entity if cpf.blank?
    return render json: { ok: false, message: "Confirme o CPF antes de solicitar o suporte." }, status: :unprocessable_entity unless session[SUPPORT_LOOKUP_SESSION_KEY] == cpf

    user = find_user_by_cpf(cpf)
    return render json: { ok: false, message: "CPF não encontrado." }, status: :not_found unless user

    participant = user.participant
    return render json: { ok: false, message: "Usuário sem participante vinculado." }, status: :unprocessable_entity unless participant
    return render json: { ok: false, message: "Usuário sem empresa vinculada." }, status: :unprocessable_entity unless participant.grupo_empresa_id.present?

    cooldown_key = "password_recovery_support_sent_at_#{cpf}"
    last_sent_at = session[cooldown_key]
    if last_sent_at.present? && Time.zone.parse(last_sent_at.to_s) > 1.minute.ago
      return render json: {
        ok: false,
        message: "Já recebemos uma solicitação recente. Aguarde um minuto para tentar novamente."
      }, status: :too_many_requests
    end

    support_participants = Participant
      .joins(:sub_grupo_empresa)
      .where(grupo_empresa_id: participant.grupo_empresa_id)
      .where.not(sub_grupo_empresa_id: nil)
      .where(sub_grupo_empresas: { can_support_access: true })
      .includes(:user)

    return render json: {
      ok: false,
      message: "Não existe nenhum usuário de suporte de acesso configurado para essa empresa."
    }, status: :unprocessable_entity if support_participants.empty?

    responsavel_participant = support_participants.find { |p| p.user.present? } || support_participants.first
    chamado = Chamado.create!(
      titulo: "Recuperação de senha - #{participant.name}",
      prioridade: "Média",
      status: "Pendente",
      local: "Login / Recuperação de senha",
      responsavel: responsavel_participant.name,
      password_recovery_support_request: true,
      observacao: <<~TEXT.strip,
        Solicitação aberta pelo fluxo de suporte da recuperação de senha.
        Nome: #{participant.name}
        CPF: #{participant.cpf}
        E-mail: #{user.email.presence || "-"}
        Empresa ID: #{participant.grupo_empresa_id}
        Subgrupo ID: #{participant.sub_grupo_empresa_id || "-"}
      TEXT
      solicitante: participant,
      solicitante_nome: participant.name,
      exibir_no_app: true
    )

    support_contact = Setting.instance.reply_to_or_default || Setting.instance.from_email_or_default

    email_warning = nil
    if support_contact.present?
      begin
        MailSettings.apply!
        PasswordRecoverySupportMailer.with(user: user, support_contact: support_contact).request_support.deliver_now
      rescue Errno::ECONNREFUSED, SocketError, IOError, SystemCallError, Net::SMTPAuthenticationError, Net::SMTPServerBusy, Net::SMTPSyntaxError, Net::SMTPFatalError, Net::SMTPUnknownError => e
        Rails.logger.warn("[password_recovery_support] chamado #{chamado.id} aberto, mas o e-mail ao suporte falhou: #{e.class} - #{e.message}")
        email_warning = " O chamado foi aberto, mas o aviso por e-mail ao suporte falhou."
      end
    end
    session[cooldown_key] = Time.current.iso8601

    render json: {
      ok: true,
      message: "Solicitação enviada com sucesso. O chamado foi aberto e o suporte será avisado.#{email_warning}"
    }
  end

  private

  def find_user_by_cpf(cpf)
    normalized = normalized_cpf(cpf)
    return nil if normalized.blank?

    User.find_for_database_authentication(cpf: normalized)
  end

  def normalized_cpf(cpf)
    cpf.to_s.gsub(/\D/, "")
  end

  def verified_session_key(cpf)
    "password_recovery_face_verified_at_#{cpf}"
  end

  def facial_verified_recently?(cpf)
    verified_at = session[verified_session_key(cpf)]
    return false if verified_at.blank?

    Time.zone.parse(verified_at.to_s) >= FACE_VERIFY_SESSION_WINDOW.ago
  rescue ArgumentError, TypeError
    false
  end

  def masked_email(email)
    local, domain = email.to_s.split("@", 2)
    return email if local.blank? || domain.blank?

    visible_local = local.length <= 2 ? local[0] : "#{local[0]}#{'*' * (local.length - 2)}#{local[-1]}"
    domain_name, tld = domain.split(".", 2)
    visible_domain = domain_name.present? ? "#{domain_name[0]}#{'*' * [domain_name.length - 1, 1].max}" : domain

    [visible_local, [visible_domain, tld].compact.join(".")].join("@")
  end

  def photo_dimensions_for(attachment)
    blob = attachment&.blob
    width = blob&.metadata&.[]("width")
    height = blob&.metadata&.[]("height")
    return { width: width, height: height } if width.present? && height.present?

    image = MiniMagick::Image.read(attachment.download)
    {
      width: image.width,
      height: image.height
    }
  rescue StandardError
    { width: nil, height: nil }
  end
end
