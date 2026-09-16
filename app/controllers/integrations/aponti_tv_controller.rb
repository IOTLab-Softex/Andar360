require "openssl"

class Integrations::ApontiTvController < ActionController::API
  before_action :authenticate_integration!

  def authenticate
    user = find_identity
    if user && user.valid_password?(params[:password].to_s) && user.aponti_tv_access?
      render_identity(user)
    else
      head :unauthorized
    end
  end

  def authorize
    user = params[:user_id].present? ? User.find_by(id: params[:user_id]) : find_identity
    user&.aponti_tv_access? ? render_identity(user) : head(:unauthorized)
  end

  private

  def session_version(user)
    OpenSSL::HMAC.hexdigest("SHA256", integration_token, "#{user.id}:#{user.encrypted_password}")
  end

  public

  def change_password
    user = User.find_by(id: params[:user_id])
    return head :unauthorized unless user&.aponti_tv_access?
    user.with_lock do
      return head :unauthorized unless user.aponti_tv_access? &&
        ActiveSupport::SecurityUtils.secure_compare(params[:session_version].to_s, session_version(user))
      password = params[:password].to_s
      if password.blank? || user.valid_password?(password)
        return render json: { errors: ["Escolha uma nova senha diferente da senha atual."] }, status: :unprocessable_entity
      end
      unless user.update(password: password, password_confirmation: params[:password_confirmation], force_password_change: false,
                         reset_password_token: nil, reset_password_sent_at: nil)
        return render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
      end
      render_identity(user)
    end
  end

  def photo
    user = User.find_by(id: params[:user_id])
    return head :unauthorized unless user&.aponti_tv_access?
    attachment = user.participant.photo
    return head :not_found unless attachment.attached?
    return head :not_found unless attachment.content_type.in?(%w[image/jpeg image/png image/webp image/gif]) && attachment.byte_size <= 5.megabytes
    response.headers["Cache-Control"] = "no-store"
    render json: { data: Base64.strict_encode64(attachment.download), content_type: attachment.content_type }
  end

  private

  def integration_token
    Setting.instance.aponti_tv_integration_token.presence || ENV["APONTI_TV_INTEGRATION_TOKEN"].presence || begin
      path = Rails.root.join("storage", "aponti_tv_integration_token")
      File.read(path).strip if File.file?(path)
    end
  end

  def authenticate_integration!
    return head :service_unavailable unless Setting.instance.aponti_tv_integration_enabled?

    expected = integration_token
    supplied = request.authorization.to_s.delete_prefix("Bearer ")
    head :unauthorized unless expected.present? &&
      ActiveSupport::SecurityUtils.secure_compare(supplied, expected)
  end

  def find_identity
    login = params[:login].to_s.strip
    return if login.blank?
    if login.include?("@")
      matches = User.where("LOWER(email) = ?", login.downcase).limit(2).to_a
      matches.one? ? matches.first : nil
    else
      User.find_for_database_authentication(cpf: login)
    end
  end

  def render_identity(user)
    response.headers["Cache-Control"] = "no-store"
    render json: {
      id: user.id, email: user.email, allowed: true,
      force_password_change: user.force_password_change?,
      has_photo: user.participant&.photo&.attached? || false,
      session_version: session_version(user)
    }
  end
end
