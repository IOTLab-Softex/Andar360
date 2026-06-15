class NotificationsController < ApplicationController
  before_action :authenticate_user!

  def marcar_como_lida
    notification = current_user.notifications.find(params[:id])
    notification.update(lida: true)

    respond_to do |format|
      format.html { redirect_back fallback_location: root_path }
      format.json { render json: { ok: true, id: notification.id } }
    end
  end

  def marcar_todas_como_lidas
    current_user.notifications.update_all(lida: true)

    respond_to do |format|
      format.html { redirect_back fallback_location: root_path, notice: "Notificacoes marcadas como lidas." }
      format.turbo_stream
      format.js
    end
  end

  def preferences
    unless current_user.update_notification_preferences!(preferences_params)
      render json: { ok: false, error: "notification_preferences column is missing" }, status: :unprocessable_entity
      return
    end

    render json: {
      ok: true,
      preferences: current_user.notification_preferences_enabled
    }
  end

  private

  def preferences_params
    params.fetch(:preferences, [])
  end
end
