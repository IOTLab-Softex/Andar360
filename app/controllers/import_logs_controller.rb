class ImportLogsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_admin!

  def index
    @datas_disponiveis = ImportLog.pluck(:created_at).map(&:to_date).uniq.sort.reverse
    @import_logs = ImportLog.all

    if params[:data].present?
      begin
        data = Date.parse(params[:data])
        @import_logs = @import_logs.where("DATE(created_at) = ?", data)
      rescue ArgumentError
        flash.now[:alert] = "⚠️ Data inválida."
      end
    end

    case params[:filtro]
    when "erro"
      @import_logs = @import_logs.where(
        "status = ? OR dados_incompletos = ? OR sem_foto = ?",
        "erro", true, true
      )
    when "sucesso"
      @import_logs = @import_logs.where.not(
        "status = ? OR dados_incompletos = ? OR sem_foto = ?",
        "erro", true, true
      )
    end

    @import_logs = @import_logs.order(created_at: :desc)
  end

  def clear_all
    if params[:data].present?
      begin
        data = Date.parse(params[:data])
        deleted = ImportLog.where("DATE(created_at) = ?", data).delete_all
        redirect_to import_logs_path, notice: "🧹 #{deleted} logs da data #{data.strftime('%d/%m/%Y')} foram apagados com sucesso."
      rescue ArgumentError
        redirect_to import_logs_path, alert: "⚠️ Data inválida."
      end
    else
      deleted = ImportLog.delete_all
      redirect_to import_logs_path, notice: "🧹 Todos os #{deleted} logs foram apagados com sucesso."
    end
  end
  
  def status
  data = Rails.cache.read('backup_status') || { status: 'parado', message: 'Nenhum processo em execução.' }
  render json: data
end

  private

  def authorize_admin!
    unless current_user&.admin?
      redirect_to root_path, alert: "Acesso não autorizado."
    end
  end
end
