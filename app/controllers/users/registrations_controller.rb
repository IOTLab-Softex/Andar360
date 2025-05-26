class Users::RegistrationsController < Devise::RegistrationsController
  skip_before_action :check_password_change_required, only: [:update]

  def update
  self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)
  prev_unconfirmed_email = resource.unconfirmed_email if resource.respond_to?(:unconfirmed_email)

  force_change_required = resource.force_password_change?

  resource.assign_attributes(account_update_params)
  resource.force_password_change = false

  resource_updated = resource.save

  if resource_updated && force_change_required
    sign_out(resource)
    redirect_to new_user_session_path, notice: "Senha alterada com sucesso. Faça login novamente."
  elsif resource_updated
    set_flash_message_for_update(resource, prev_unconfirmed_email)
    bypass_sign_in resource, scope: resource_name
    redirect_to after_update_path_for(resource), notice: "Senha alterada com sucesso."
  else
    clean_up_passwords resource
    set_minimum_password_length
   flash.now[:alert] = resource.errors.full_messages.join(". ")
render "devise/registrations/edit", status: :unprocessable_entity

  end
end



  protected

  def update_resource(resource, params)
    resource.update_without_password(params)
  end

  def after_update_path_for(resource)
    edit_user_registration_path # permanece na edição se quiser continuar editando depois
  end
end
