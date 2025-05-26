class ImportLogsController < ApplicationController
      before_action :authenticate_user!
  before_action :authorize_admin!
  def index
    # Lista de datas únicas para o filtro
    @datas_disponiveis = ImportLog.pluck(:created_at).map { |d| d.to_date }.uniq.sort.reverse

    @import_logs = ImportLog.all.order(created_at: :desc)

    # Filtro por tipo
    case params[:filtro]
    when "erro"
      @import_logs = @import_logs.select do |log|
        log.status == "erro" || log.dados_incompletos || log.sem_foto
      end
    when "sucesso"
      @import_logs = @import_logs.select do |log|
        log.status != "erro" && !log.dados_incompletos && !log.sem_foto
      end
    end

    # Filtro por data única
    if params[:data].present?
      data_selecionada = Date.parse(params[:data])
      @import_logs = @import_logs.select { |log| log.created_at.to_date == data_selecionada }
    end
  end

   private

  def authorize_admin!
    unless current_user&.admin?
      redirect_to root_path, alert: "Acesso não autorizado."
    end
  end
end
