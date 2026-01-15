class WebPushService
  def self.send_to_user(user, title:, body:, url: "/")
    s = Setting.first
    return if s.blank? || s.vapid_public_key.blank? || s.vapid_private_key.blank?

    user.push_subscriptions.find_each do |sub|
      payload = {
        title: title,
        body: body,
        url: url,
        icon: "/icon.png",
        badge: "/icon.png"
      }.to_json

      begin
        Webpush.payload_send(
          message: payload,
          endpoint: sub.endpoint,
          p256dh: sub.p256dh,
          auth: sub.auth,
          vapid: {
            subject: (s.vapid_subject.presence || "mailto:suporte@seu-dominio.com"),
            public_key: s.vapid_public_key,
            private_key: s.vapid_private_key
          }
        )
      rescue Webpush::InvalidSubscription, Webpush::ExpiredSubscription
        sub.destroy
      rescue => e
        Rails.logger.error("[WebPushService] erro enviando push: #{e.class} - #{e.message}")
        Rails.logger.error(e.backtrace.join("\n")) # Log completo do erro
      end
    end
  end
end
