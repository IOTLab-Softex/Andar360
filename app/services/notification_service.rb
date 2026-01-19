# app/services/notification_service.rb
class NotificationService
  class << self
    def notify_users_for(record, only_if_in_period: true)
      # 👉 Ajuste importante: só checa periodo se o record tiver esse método
      if only_if_in_period && record.respond_to?(:dentro_do_periodo_de_aviso?) &&
           !record.dentro_do_periodo_de_aviso?
        return
      end

      # 🔹 URL dinâmica por tipo de registro
      url = notificavel_url(record)

      User.includes(:participant).find_each do |user|
        # regra: cliente só se exibir_no_app? (quando existir)
        if user.client? && record.respond_to?(:exibir_no_app?) && !record.exibir_no_app?
          next
        end

        titulo =
          if record.respond_to?(:dia_previsto?) && record.dia_previsto?
            "Manutenção é hoje: #{record.try(:titulo) || record.class.model_name.human}"
          else
            record.try(:titulo).presence ||
              record.class.model_name.human
          end

        corpo =
          if record.respond_to?(:data_prevista) && record.data_prevista.present?
            "A manutenção '#{record.try(:titulo)}' está prevista para #{I18n.l(record.data_prevista)}"
          else
            record.try(:descricao).to_s.truncate(140)
          end

        notif = Notification.find_or_initialize_by(user: user, notificavel: record)
        notif.titulo = titulo
        notif.corpo  = corpo
        notif.lida   = false
        notif.url    = url if notif.respond_to?(:url=)
        notif.save!

        WebPushService.send_to_user(
          user,
          title: notif.titulo,
          body:  notif.corpo,
          url:   url
        )
      end
    end

    private

    def notificavel_url(record)
      helpers = Rails.application.routes.url_helpers

      case record
      when Chamado
        helpers.chamado_path(record)                 # /chamados/:id
      when ManutencaoProgramada
        helpers.manutencao_programada_path(record)   # /manutencao_programadas/:id (ajusta pro seu nome de rota real)
      when Reservation
        helpers.reservation_path(record)             # se quiser notificar reserva
      else
        "/notifications"                             # fallback
      end
    end
  end
end
