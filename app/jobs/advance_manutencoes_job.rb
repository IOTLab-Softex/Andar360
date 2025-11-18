# app/jobs/advance_manutencoes_job.rb
class AdvanceManutencoesJob < ApplicationJob
  queue_as :default

  def perform
    ManutencaoProgramada.where.not(data_prevista: nil).find_each do |m|
      m.avançar_ate_futuro!(referencia: Date.current)
    end
  end
end
