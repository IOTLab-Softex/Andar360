# app/services/web_push_service.rb
require "open3"

class WebPushService
  NODE_PUSH_SCRIPT = Rails.root.join("node_scripts", "send_push.js")

  def self.send_to_user(user, title:, body:, url: "/")
    s = Setting.first
    unless s&.vapid_public_key.present? && s&.vapid_private_key.present?
      Rails.logger.error "[WebPushService] VAPID não configurado em Settings."
      return 0
    end

    subject = s.vapid_subject.presence || "mailto:admin@srs.local"
    sent = 0

    user.push_subscriptions.find_each do |sub|
      Rails.logger.info "[WebPushService] Enviando push (NODE) para sub #{sub.id} (user_id=#{user.id})"

      payload = {
        title: title,
        body:  body,
        url:   url
      }

      cmd = [
        "node",
        NODE_PUSH_SCRIPT.to_s,
        sub.endpoint.to_s,
        sub.p256dh.to_s,
        sub.auth.to_s,
        s.vapid_public_key.to_s,
        s.vapid_private_key.to_s,
        subject.to_s,
        payload.to_json
      ]

      stdout, stderr, status = Open3.capture3(*cmd)

      if status.success?
        Rails.logger.info "[WebPushService] OK sub #{sub.id}: #{stdout.strip}"
        sent += 1
      else
        msg = stderr.to_s.strip.presence || stdout.to_s.strip
        Rails.logger.error "[WebPushService] ERRO sub #{sub.id}: exit=#{status.exitstatus} msg=#{msg}"

        # 👇 Se retorno indicar 410 (subscription expirada), removemos do banco
        if msg.include?("410") || msg.include?("unsubscribed or expired")
          Rails.logger.warn "[WebPushService] Removendo push subscription expirada #{sub.id} (410 Gone)"
          sub.destroy
        end
      end
    end

    sent
  end
end
