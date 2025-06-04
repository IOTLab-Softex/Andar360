class ReloadFacialSchedulerJob
  def self.reload!
    return unless defined?(Rails::Server)

    scheduler = Rufus::Scheduler.singleton

    # Cancela o job anterior
    $facial_check_job&.unschedule

    setting = Setting.first
    valor = setting&.tempo_verificacao_online || 5
    unidade = setting&.tempo_verificacao_online_unidade || "minutos"

    intervalo = case unidade
                when "segundos" then "#{valor}s"
                when "minutos"  then "#{valor}m"
                else "5m"
                end

    $facial_check_job = scheduler.every intervalo do
      now = Time.current

      active_exists = Reservation.where(
        "starts_at <= ? AND ends_at >= ? AND cancelada_em IS NULL AND sent_to_facial IS NOT TRUE",
        now, now
      ).exists?

      if active_exists
        Rails.logger.info "[⏱] Acesso facial: reservas ativas detectadas - executando verificação"
        CheckFacialAccessJob.perform_later
      else
        Rails.logger.info "[⏱] Nenhuma reserva ativa no momento - verificação ignorada"
      end
    end

    Rails.logger.info "[⏱] Scheduler reiniciado com intervalo: #{intervalo}"
  end
end
