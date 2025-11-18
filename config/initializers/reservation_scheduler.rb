return unless defined?(Rails::Server)

require "rufus-scheduler"
$scheduler ||= Rufus::Scheduler.new

module ReservationScheduler
  def self.init!
    # Limpa jobs antigos
    %w[reservation_job device_check_job reservation_reminder_job reservation_start_notification_job].each do |tag|
      $scheduler.jobs(tag: tag).each(&:unschedule)
    end

    setting   = ::Setting.first
    valor     = setting&.tempo_checagem_reservas || 5
    unidade   = setting&.tempo_checagem_reservas_unidade || "minutos"
    intervalo = (unidade == "segundos") ? "#{valor}s" : "#{valor}m"

    # Job 1: envio / finalização / no-show
    $scheduler.every intervalo, tag: "reservation_job" do
      now = Time.current

      # Enviar participantes (solicitantes)
      Reservation.where("starts_at <= ? AND solicitantes_enviados_em IS NULL", now).find_each do |reservation|
        AddParticipantToFacialJob.perform_later(reservation.id)
        reservation.update_column(:solicitantes_enviados_em, now)
      end

      # Finalizar reservas
      Reservation.where("ends_at <= ? AND finalizada_em IS NULL", now).find_each do |reservation|
        RemoverParticipantesDoDispositivoJob.perform_later(reservation.id)
        reservation.update_column(:finalizada_em, now)
      end

      # No-show (início passou de 1 min e ainda está dentro do período)
      limite = now - 1.minute
      Reservation.where("starts_at <= ? AND ends_at > ?", limite, now)
                 .where(cancelada_em: nil, no_show_notificado_em: nil)
                 .find_each do |reservation|
        NotificarNoShowReservaJob.perform_later(reservation.id)
        reservation.update_column(:no_show_notificado_em, now)
        
      end
    end

    # Job 2: Verificar dispositivos
    valor1     = setting&.tempo_verificacao_online || 5
    unidade1   = setting&.tempo_verificacao_online_unidade || "minutos"
    intervalo1 = (unidade1 == "segundos") ? "#{valor1}s" : "#{valor1}m"

    $scheduler.every intervalo1, tag: "device_check_job" do
      CheckDeviceStatusJob.perform_later
    end

    # Job 3: Notificação no início da reserva (janela de 2 minutos)
# config/initializers/reservation_scheduler.rb (trecho)
$scheduler.every "60s", tag: "reservation_prestart_notification_job" do
  now = Time.current
  # Busca reservas que começam daqui a pouco (ex.: nas próximas 30 min) e ainda não foram notificadas
  Reservation.where(cancelada_em: nil, finalizada_em: nil, pre_inicio_notificado_em: nil)
             .where("starts_at > ? AND starts_at <= ?", now, now + 30.minutes)
             .find_each do |reservation|
    # O job checa se está exatamente dentro da janela (ex.: 2 min) e deduplica
    NotificarPreInicioReservaJob.perform_later(reservation.id)
  end
end


  end
end

Rails.application.config.after_initialize do
  ReservationScheduler.init!
end
