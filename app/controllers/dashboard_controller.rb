class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @rooms = Room.includes(:reservations)
  if current_user&.admin? || current_user&.operador?
      @chamados = Chamado.order(created_at: :desc)
    else
      grupo_empresa_id = current_user.participant&.grupo_empresa_id

      @chamados = Chamado
        .joins("INNER JOIN participants ON participants.id = chamados.solicitante_id")
        .where("participants.grupo_empresa_id = ?", grupo_empresa_id)
        .order(created_at: :desc)
    end

    @manutencao_programadas = if current_user.admin? || current_user.role == "operador"
        ManutencaoProgramada.order(data_prevista: :asc)
      else
        ManutencaoProgramada.where(exibir_no_app: true).order(data_prevista: :asc)
      end

    @avisos_manutencao = ManutencaoProgramada.select do |m|
      m.dentro_do_periodo_de_aviso?
    end
    @avisos_tokens = (@avisos_manutencao || []).map do |m|
      versao = "#{m.updated_at.to_i}-#{m.data_prevista&.strftime("%Y-%m-%d")}"
      "mp:#{m.id}:#{versao}"
    end
    @ack_ns = "u#{current_user.id}"  # opcional, para namespacing por usuário
     data = DashboardQuery.new(current_user).call

    @rooms                  = data.rooms
    @chamados               = data.chamados
    @chamados_counts        = data.chamados_counts
    @manutencao_programadas = data.manutencoes
    @avisos_manutencao      = data.avisos_manutencao
    @avisos_tokens          = data.avisos_tokens
    @ack_ns                 = data.ack_ns
    @kpis                   = data.kpis
  end
  
  
end
