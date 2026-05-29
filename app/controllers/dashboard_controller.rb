class DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :set_dashboard_card_order, only: :index

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
    @minhas_reservas        = data.minhas_reservas
    @manutencao_programadas = data.manutencoes
    @avisos_manutencao      = data.avisos_manutencao
    @avisos_tokens          = data.avisos_tokens
    @ack_ns                 = data.ack_ns
    @encomendas             = data.encomendas
    @items                  = data.items
    @formularios_pendentes  = data.formularios_pendentes
    @kpis                   = data.kpis
  end
  
  def refresh
    data = DashboardQuery.new(current_user).call

    @rooms                  = data.rooms
    @chamados               = data.chamados
    @chamados_counts        = data.chamados_counts
    @minhas_reservas        = data.minhas_reservas
    @manutencao_programadas = data.manutencoes
    @avisos_manutencao      = data.avisos_manutencao
    @avisos_tokens          = data.avisos_tokens
    @ack_ns                 = data.ack_ns
    @encomendas             = data.encomendas
    @items                  = data.items
    @formularios_pendentes  = data.formularios_pendentes
    @kpis                   = data.kpis
    @dashboard_hidden_cards = helpers.hidden_dashboard_card_ids_for(current_user)
    @dashboard_card_order   = helpers.ordered_dashboard_card_ids_for(current_user)

    respond_to do |format|
      format.turbo_stream
    end
  end

  def update_card_order
    available_cards = helpers.dashboard_available_card_ids_for(current_user)
    requested_order = Array(params[:order]).map(&:to_s)
    requested_hidden_cards = Array(params[:hidden_cards]).map(&:to_s)
    normalized_order = (requested_order & available_cards) + (available_cards - requested_order)
    normalized_hidden_cards = requested_hidden_cards & available_cards

    current_user.update!(dashboard_card_order: normalized_order, dashboard_hidden_cards: normalized_hidden_cards)

    render json: { ok: true, order: normalized_order, hidden_cards: normalized_hidden_cards }
  rescue ActiveRecord::ActiveRecordError
    render json: { ok: false, message: "Nao foi possivel salvar a ordem do dashboard." }, status: :unprocessable_entity
  end

  private

  def set_dashboard_card_order
    @dashboard_card_order = helpers.ordered_dashboard_card_ids_for(current_user)
    @dashboard_hidden_cards = helpers.hidden_dashboard_card_ids_for(current_user)
  end
end
