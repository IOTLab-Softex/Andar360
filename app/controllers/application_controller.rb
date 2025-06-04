class ApplicationController < ActionController::Base
   before_action :configure_permitted_parameters, if: :devise_controller?
  include EmpresaScoping
  before_action :authenticate_user!
  helper_method :scoped_participants, :scoped_grupo_empresas
  before_action :check_password_change_required
  def scoped_participants
    if current_user.admin?
      Participant.all
    else
      Participant.where(grupo_empresa_id: current_user.participant&.grupo_empresa_id)
    end
  end

  def scoped_grupo_empresas
    if current_user.admin? || current_user.operador?

      GrupoEmpresa.all
    else
      GrupoEmpresa.where(id: current_user.participant&.grupo_empresa_id)
    end
  end

  def scoped_participants
  if current_user.admin? || current_user.operador?

    Participant.all
  else
    Participant.where(grupo_empresa_id: current_user.participant&.grupo_empresa_id)
  end
end

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :configure_permitted_parameters, if: :devise_controller?

  def authorize_empresa!(registro)
  unless current_user.admin? || registro.grupo_empresa_id == current_user.participant&.grupo_empresa_id
    redirect_to root_path, alert: "⚠️ Acesso não autorizado."
  end
end


def check_password_change_required
  return unless user_signed_in?
  return unless current_user.force_password_change?
  return if request.path == edit_user_registration_path
  flash[:alert] = "Você precisa definir uma nova senha antes de continuar."
  redirect_to edit_user_registration_path
end



protected

def configure_permitted_parameters
  devise_parameter_sanitizer.permit(:sign_in, keys: [:cpf])
  devise_parameter_sanitizer.permit(:sign_up, keys: [:cpf, :role])
  devise_parameter_sanitizer.permit(:account_update, keys: [:cpf, :role, :password, :password_confirmation, :current_password])

  
end

end
