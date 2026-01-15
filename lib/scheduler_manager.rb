# app/lib/scheduler_manager.rb

class SchedulerManager
  SCHEDULERS = %w[
    FacialAccessScheduler
    ReservationScheduler
    BackupScheduler
  ].freeze

  def self.reload_all
    puts "[🔁] Reiniciando todos os schedulers..."

    SCHEDULERS.each do |name|
      klass = name.safe_constantize

      if klass && klass.respond_to?(:init!)
        klass.init!
        puts "[✅] #{name} reiniciado."
      else
        puts "[⚠️] #{name} não encontrado (ignorando)."
      end
    end

    puts "[✅] Schedulers processados."
    true
  end
end
