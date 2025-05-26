return unless defined?(Rails::Server)

require 'rufus-scheduler'
$scheduler ||= Rufus::Scheduler.new

module ReservationScheduler
  def self.init!
    # Cancela os jobs anteriores, se existirem
      $scheduler.jobs(tag: 'reservation_job').each(&:unschedule)
    $scheduler.jobs(tag: 'device_check_job').each(&:unschedule)

setting = ::Setting.first # Use :: para garantir que é o model global
    valor = setting&.tempo_checagem_reservas || 5
    unidade = setting&.tempo_checagem_reservas_unidade || "minutos"
    intervalo = unidade == "segundos" ? "#{valor}s" : "#{valor}m"
    puts "[📅] Inicializando ReservationScheduler..."

    # Job 1: Enviar participantes
    $scheduler.every intervalo, tag: 'reservation_job' do
      now = Time.current

      Reservation.where('starts_at <= ? AND solicitantes_enviados_em IS NULL', now).find_each do |reservation|
        Rails.logger.info "[Scheduler] Enviando solicitante/responsável para reserva #{reservation.id}"
        AddParticipantToFacialJob.perform_later(reservation.id)
        reservation.update(solicitantes_enviados_em: now)
      end

      Reservation.where('ends_at <= ? AND finalizada_em IS NULL', now).find_each do |reservation|
        Rails.logger.info "[Scheduler] Removendo participantes da reserva encerrada #{reservation.id}"
        RemoverParticipantesDoDispositivoJob.perform_later(reservation.id)
        reservation.update(finalizada_em: now)
      end
    end

     valor1 = setting&.tempo_verificacao_online || 5
    unidade1 = setting&.tempo_verificacao_online_unidade || "minutos"
    intervalo1 = unidade == "segundos" ? "#{valor}s" : "#{valor}m"

    # Job 2: Verificar dispositivos online
    $scheduler.every intervalo1, tag: 'device_check_job' do
      begin
        Rails.logger.info "[Scheduler] Verificando status dos dispositivos"
        CheckDeviceStatusJob.perform_later
      rescue => e
        Rails.logger.error("[RufusScheduler] Erro ao agendar CheckDeviceStatusJob: #{e.message}")
      end
    end

  end
end

Rails.application.config.after_initialize do
# Chamada inicial ao carregar o sistema
ReservationScheduler.init!
end