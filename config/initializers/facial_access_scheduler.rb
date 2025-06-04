# config/initializers/facial_access_scheduler.rb
return unless defined?(Rails::Server)

require 'rufus-scheduler'

$scheduler ||= Rufus::Scheduler.new

module FacialAccessScheduler
  def self.init!
    $scheduler.jobs(tag: 'facial_check_job').each(&:unschedule)

    setting = ::Setting.first # Use :: para garantir que é o model global
    valor = setting&.tempo_checagem_acesso || 5
    unidade = setting&.tempo_checagem_acesso_unidade || "minutos"
    intervalo = unidade == "segundos" ? "#{valor}s" : "#{valor}m"

   $scheduler.every intervalo, tag: 'facial_check_job' do
     Rails.logger.info "tempo_verificacao_online #{intervalo}"
  if Reservation.where("starts_at <= ? AND ends_at >= ? AND cancelada_em IS NULL AND sent_to_facial IS NOT TRUE", Time.current, Time.current).exists?
    Rails.logger.info "[Facial] Verificando acesso facial..."
    CheckFacialAccessJob.perform_later
  end
end



  end
end

# ✅ Só inicia o agendamento após todos os models estarem carregados
Rails.application.config.after_initialize do
  FacialAccessScheduler.init!
end
