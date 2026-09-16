class Users::SessionsController < Devise::SessionsController
  skip_forgery_protection only: :create
  skip_before_action :authenticate_user!, :check_password_change_required, only: :recovery

  def recovery
    # Links antigos podem apontar para /recuperar-senha. Se vierem com um token,
    # a ?nica tela correta ? a de escolha da nova senha, sem abrir o modal.
    if params[:reset_password_token].present?
      redirect_to edit_user_password_path(reset_password_token: params[:reset_password_token])
      return
    end

    self.resource = resource_class.new
    render :new
  end

  def create
    cpf = params.dig(resource_name, :cpf).to_s
    password = params.dig(resource_name, :password).to_s
    remember = ActiveModel::Type::Boolean.new.cast(params.dig(resource_name, :remember_me))

    self.resource = resource_class.find_for_database_authentication(cpf: cpf)

    if resource&.valid_password?(password) && resource.active_for_authentication?
      resource.remember_me = remember if resource.respond_to?(:remember_me=)
      set_flash_message!(:notice, :signed_in)
      sign_in(resource_name, resource)
      respond_with resource, location: after_sign_in_path_for(resource)
      return
    end

    if resource&.valid_password?(password)
      set_flash_message!(:alert, resource.inactive_message)
    else
      flash.now[:alert] = I18n.t("devise.failure.invalid")
    end

    self.resource = resource_class.new(sign_in_params)
    clean_up_passwords(resource)
    respond_with_navigational(resource) { render :new, status: :unprocessable_entity }
  end

  def destroy
    super
  end
end
