class PushSubscriptionsController < ApplicationController
  before_action :authenticate_user!

def vapid_public_key
  s = Setting.first
  key = s&.vapid_public_key.to_s

  if key.present?
    render json: { publicKey: key }
  else
    render json: { error: "VAPID não configurado" }, status: :unprocessable_entity
  end
end



 def create
  sub = params.require(:subscription).permit(:endpoint, keys: [:p256dh, :auth])

  keys = sub[:keys] || {}
  p256dh = keys[:p256dh] || keys["p256dh"]
  auth   = keys[:auth]   || keys["auth"]

  record = current_user.push_subscriptions.find_or_initialize_by(endpoint: sub[:endpoint])
  record.p256dh = p256dh
  record.auth   = auth
  record.save!

  render json: { ok: true }
end


  def destroy
    current_user.push_subscriptions.where(endpoint: params[:endpoint]).delete_all
    head :ok
  end
end
