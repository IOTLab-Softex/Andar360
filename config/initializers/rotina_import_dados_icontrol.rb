return unless defined?(Rails::Server)

require 'rufus-scheduler'
$scheduler ||= Rufus::Scheduler.new

module BackupScheduler
  def self.init!
    # Cancela o job anterior, se já estiver agendado
   $scheduler.jobs(tag: 'backup_job').each(&:unschedule)

    puts "[🗂] Inicializando BackupScheduler..."

    setting = ::Setting.first
    hora = setting&.horario_rotina_importacao

    cron = begin
      Time.parse(hora.to_s).strftime("%M %H * * *")
    rescue => e
      Rails.logger.warn "[BackupScheduler] Erro ao processar hora: #{e.message}"
      "0 3 * * *" # fallback para 3h da manhã
    end

    $scheduler.cron cron, tag: 'backup_job' do
      Rails.logger.info "[⏰] Executando DownloadZipBackupIcontrolJob via Rufus"
      DownloadZipBackupIcontrolJob.perform_now


    end


  end

end
Rails.application.config.after_initialize do
# Chamada inicial
BackupScheduler.init!
end