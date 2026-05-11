class ApplicationController < ActionController::Base

   before_action :configure_permitted_parameters, if: :devise_controller?
  include EmpresaScoping
  before_action :authenticate_user!
  helper_method :scoped_participants, :scoped_grupo_empresas
  before_action :check_password_change_required

 helper_method :can_view_monitoring?, :can_manage_items?, :can_manage_encomendas?, :can_access_portaria?

  def can_view_monitoring?
    subgrupo_permission_enabled?(:can_view_monitoring)
  end

  def can_manage_items?
    current_user&.admin? || current_user&.operador? || subgrupo_permission_enabled?(:can_manage_items)
  end

  def can_manage_encomendas?
    current_user&.admin? || current_user&.operador? || subgrupo_permission_enabled?(:can_manage_encomendas)
  end

  def can_access_portaria?
    can_manage_items? || can_manage_encomendas?
  end

  def after_sign_in_path_for(resource)
  dashboard_path
  end

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

def subgrupo_permission_enabled?(permission)
  return false unless current_user

  sub = current_user.participant&.sub_grupo_empresa
  return false unless sub&.respond_to?(permission)

  !!sub.public_send(permission)
end


  def nome_do_usuario
    current_user&.participant&.name || current_user&.name || "Desconhecido"
  end
  helper_method :nome_do_usuario
  
   def authorize_admin!
    unless current_user&.admin? || current_user&.operador?
      respond_to do |format|
        format.html { redirect_to root_path, alert: "⚠️ Acesso permitido" }
        format.json { head :forbidden }
      end
    end
  end

    def flash_success(message, sound: "success")
    flash[:notice] = message
    flash[:flash_sound] = sound # ex: "success"
  end

  # helper para erro
  def flash_error(message, sound: "error")
    flash[:alert] = message
    flash[:flash_sound] = sound # ex: "error"
  end
  
protected

def configure_permitted_parameters
  devise_parameter_sanitizer.permit(:sign_in, keys: [:cpf])
  devise_parameter_sanitizer.permit(:sign_up, keys: [:cpf, :role])
  devise_parameter_sanitizer.permit(:account_update, keys: [:cpf, :role, :password, :password_confirmation, :current_password])

  
end

end
