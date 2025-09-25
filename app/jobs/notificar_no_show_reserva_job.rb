# app/jobs/notificar_no_show_reserva_job.rb
class NotificarNoShowReservaJob < ApplicationJob
  queue_as :default

  def perform(reservation_id)
    reservation = Reservation.find_by(id: reservation_id)
    return Rails.logger.info("[NoShow] reserva #{reservation_id} não encontrada") unless reservation
    return Rails.logger.info("[NoShow] reserva #{reservation.id} cancelada/finalizada") if reservation.cancelada_em || reservation.finalizada_em

    # 1) Já passou 1 minuto do início?
    return Rails.logger.info("[NoShow] ainda não passou 1 minuto da reserva #{reservation.id}") if Time.current < reservation.starts_at + 1.minute

    # 2) Houve algum acesso?
    return Rails.logger.info("[NoShow] já houve acesso na reserva #{reservation.id}") if AccessLog.where(reservation_id: reservation.id).exists?

    # 3) Já notificou?
    return Rails.logger.info("[NoShow] reserva #{reservation.id} já notificada em #{reservation.no_show_notificado_em}") if reservation.no_show_notificado_em.present?

    # === Destinatários: admin & operador SEMPRE; client SOMENTE se for da mesma empresa do SOLICITANTE ===
    solicitante_grupo_id = reservation.solicitante&.grupo_empresa_id

    User.includes(:participant).find_each do |user|
      if user.client?
        # Só cliente da mesma empresa do solicitante
        user_grupo_id = user.participant&.grupo_empresa_id
        next if solicitante_grupo_id.blank? || user_grupo_id != solicitante_grupo_id
      else
        # Apenas admin ou operador
        next unless user.admin? || user.role == "operador"
      end

      titulo = "⚠️ Ausencia na reserva: #{reservation.room&.name}"
      corpo  = "Passou 1 minuto do início (#{I18n.l(reservation.starts_at, format: :short)}) "\
               "e ninguém registrou acesso na sala \"#{reservation.room&.name}\"."

      # Evita duplicação se o scheduler disparar mais de uma vez antes de marcar no_show_notificado_em
      Notification.find_or_create_by!(
        user: user,
        notificavel: reservation,
        titulo: titulo,
        corpo:  corpo
      ) { |n| n.lida = false }
    end

    reservation.update!(no_show_notificado_em: Time.current)
    Rails.logger.info "[NoShow] Notificação (1 min) gerada para #{titulo_reserva(reservation)}"
  end

  private

  def titulo_reserva(reservation)
    reservation.title.presence || "Reserva ##{reservation.id}"
  end
end
