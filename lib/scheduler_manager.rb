# app/lib/scheduler_manager.rb
class SchedulerManager
  def self.reload_all
    puts "[🔁] Reiniciando todos os schedulers..."
    FacialAccessScheduler.init!
    ReservationScheduler.init!
    BackupScheduler.init!
    puts "[✅] Todos os schedulers foram reiniciados com sucesso."
  end
end
