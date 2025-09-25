# app/jobs/notificar_pre_inicio_reserva_job.rb
class NotificarPreInicioReservaJob < ApplicationJob
  queue_as :default

  # minutos antes do início (pode vir do Setting)
  ANTECEDENCIA_MINUTOS = 2

  def perform(reservation_id)
    reservation = Reservation.find_by(id: reservation_id)
    return Rails.logger.info("[PreStart] reserva #{reservation_id} não encontrada") unless reservation
    return Rails.logger.info("[PreStart] reserva #{reservation.id} cancelada/finalizada") if reservation.cancelada_em || reservation.finalizada_em

    # Já notificou?
    return Rails.logger.info("[PreStart] reserva #{reservation.id} já notificada em #{reservation.pre_inicio_notificado_em}") if reservation.pre_inicio_notificado_em.present?

    # Só dentro da janela: agora >= starts_at - N e ainda não começou
    now = Time.current
    return Rails.logger.info("[PreStart] fora da janela (#{reservation.id})") unless now >= reservation.starts_at - ANTECEDENCIA_MINUTOS.minutes && now < reservation.starts_at

    empresa_id = reservation.grupo_empresa_id.presence || reservation.solicitante&.grupo_empresa_id
    return Rails.logger.info("[PreStart] reserva #{reservation.id} sem empresa associada") if empresa_id.blank?

    # Destinatários: somente clientes da empresa (como você pediu)
    destinatarios = User.includes(:participant).where(role: "client")
                        .where(participants: { grupo_empresa_id: empresa_id })

    # (Opcional) incluir admin/operador:
    # destinatarios += User.where(role: ["admin", "operador"])

    titulo = "⏰ Sua reserva começa em #{ANTECEDENCIA_MINUTOS} min: #{reservation.room&.name}"
    corpo  = "A reserva \"#{reservation.title}\" inicia às "\
             "#{I18n.l(reservation.starts_at, format: :short)}. "\
             "Dirija-se à sala #{reservation.room&.name}."

    destinatarios.uniq.each do |user|
      Notification.find_or_create_by!(
        user: user,
        notificavel: reservation,
        titulo: titulo,
        corpo:  corpo
      ) { |n| n.lida = false }
    end

    reservation.update_column(:pre_inicio_notificado_em, Time.current)
    Rails.logger.info "[PreStart] Notificação gerada para reserva #{reservation.id}"
  end
end
