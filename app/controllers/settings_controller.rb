class SettingsController < ApplicationController
      before_action :authenticate_user!
  before_action :authorize_admin!
  
  def index
      @setting = Setting.first_or_create
  render :edit
  end

  def update
    @setting = Setting.first
    if @setting.update(setting_params)
      redirect_to settings_path, notice: "Configurações atualizadas"
    else
      render :index
    end
  end

  private

    def authorize_admin!
    unless current_user&.admin?
      redirect_to root_path, alert: "Acesso não autorizado."
    end
  end
  
  def setting_params
    params.require(:setting).permit(
      :backup_dir,
      :tempo_checagem_acesso,
      :tempo_checagem_acesso_unidade,
      :tempo_checagem_reservas,
      :tempo_checagem_reservas_unidade,
      :limite_horas_turno_reservas_manha,
      :limite_horas_turno_reservas_tarde,
      :limite_horas_turno_reservas_noite,
      :tempo_verificacao_online,
      :tempo_verificacao_online_unidade,
      :horario_rotina_importacao
    )
  end
end
