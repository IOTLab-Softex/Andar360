require "digest/md5"
class ManutencaoProgramadasController < ApplicationController
  include VisualizacaoHelper
  before_action :require_operador_ou_admin!, only: %i[
    index new create edit update destroy adiar anexar_arquivo remove_arquivo
  ]

  # Carrega o registro apenas nas ações que realmente recebem :id
  before_action :set_manutencao_programada, only: %i[
    show edit update destroy adiar anexar_arquivo remove_arquivo
  ]
  # app/controllers/manutencao_programadas_controller.rb
def index
  if current_user.admin? || current_user.role == "operador"
    @manutencao_programadas = ManutencaoProgramada.all
  else
    @manutencao_programadas = ManutencaoProgramada.where(exibir_no_app: true)
  end

  if params[:categoria].present? && params[:categoria] != "Todas as categorias"
    @manutencao_programadas = @manutencao_programadas.where(categoria: params[:categoria])
  end
  if params[:responsavel].present? && params[:responsavel] != "Todos os responsáveis"
    @manutencao_programadas = @manutencao_programadas.where(responsavel: params[:responsavel])
  end
  if params[:periodicidade].present? && params[:periodicidade] != "Todas as periodicidades"
    @manutencao_programadas = @manutencao_programadas.where(periodicidade: params[:periodicidade])
  end
  if params[:inicio].present? && params[:fim].present?
    @manutencao_programadas = @manutencao_programadas.where(data_prevista: params[:inicio]..params[:fim])
  end

  # ⚠️ Remova este loop de criação de notificações daqui se já usa o callback no model.
  # (Ele já cria/atualiza as notificações em after_commit.)
  # ManutencaoProgramada.all.each do |...| end

  # 🔔 Base para o modal: quem está no período de aviso
   @avisos_manutencao =
    @manutencao_programadas
      .where.not(data_prevista: nil)
      .where(<<~SQL)
        (
          (dias_para_aviso IS NOT NULL AND CURRENT_DATE BETWEEN (data_prevista - dias_para_aviso) AND data_prevista)
           OR
          (data_de_aviso IS NOT NULL AND CURRENT_DATE BETWEEN data_de_aviso AND data_prevista)
        )
      SQL
      .order(:data_prevista)

  # >>> ADICIONE AQUI <<<
  @avisos_tokens = @avisos_manutencao.map do |m|
    versao = "#{m.updated_at.to_i}-#{m.data_prevista&.strftime('%Y-%m-%d')}"
    "mp:#{m.id}:#{versao}"
  end
  @ack_ns = "u#{current_user.id}"
  # >>> FIM DO BLOCO NOVO <<<

  # (opcional) se ainda quiser manter a @avisos_key via MD5:
  base_para_hash = @avisos_manutencao.map { |m|
    [m.id, m.data_prevista&.to_s, m.data_de_aviso&.to_s, m.titulo.to_s, m.local.to_s, m.periodicidade.to_s, m.updated_at.to_i].join("-")
  }.join("|")
  @avisos_key = Digest::MD5.hexdigest(base_para_hash.presence || "vazio")
end


  def show
    marcar_como_visualizado("manutencao", @manutencao_programada.id)
  end

  def new
    @manutencao_programada = ManutencaoProgramada.new
  end

  def edit

    @manutencao_programada = ManutencaoProgramada.includes(:ocorrencias).find(params[:id])

  end

  def create
    @manutencao_programada = ManutencaoProgramada.new(manutencao_programada_params)

    respond_to do |format|
      if @manutencao_programada.save
        format.html { redirect_to dashboard_path, notice: "Manutenção programada criada com sucesso." }

        format.json { render :show, status: :created, location: @manutencao_programada }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @manutencao_programada.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @manutencao_programada.update(manutencao_programada_params)
        format.html { redirect_to dashboard_path, notice: "Manutenção programada atualizada com sucesso." }
        format.json { render :show, status: :ok, location: @manutencao_programada }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @manutencao_programada.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @manutencao_programada.destroy!
    respond_to do |format|
      format.html { redirect_to dashboard_path, status: :see_other, notice: "Manutenção programada excluída com sucesso." }
      format.json { head :no_content }
    end
  end

  # manutencao_programadas_controller.rb
  def anexar_arquivo
    @manutencao_programada = ManutencaoProgramada.find(params[:id])
    @arquivo_anexo = @manutencao_programada.arquivo_anexos.build(nome: params[:nome])
    @arquivo_anexo.arquivo.attach(params[:arquivo])

    if @arquivo_anexo.save
      redirect_to edit_manutencao_programada_path(@manutencao_programada), notice: "Arquivo anexado com sucesso."
    else
      redirect_to edit_manutencao_programada_path(@manutencao_programada), alert: "Erro ao anexar o arquivo."
    end
  end

  # app/controllers/manutencao_programadas_controller.rb
  def remove_arquivo
    mp = ManutencaoProgramada.find(params[:id])
    blob = ActiveStorage::Blob.find_signed(params[:blob_signed_id])

    # Encontra a *attachment* cujo blob_id bate com o blob que você quer remover:
    attachment = mp.arquivos_attachments.find_by(blob_id: blob.id)

    if attachment
      attachment.purge_later
      notice = "Arquivo removido com sucesso."
    else
      notice = "Anexo não encontrado."
    end

    redirect_back fallback_location: edit_manutencao_programada_path(mp), notice: notice
  end

  def adiar
    @manutencao_programada = ManutencaoProgramada.find(params[:id])

    nova_data = case @manutencao_programada.periodicidade&.downcase
      when "diário", "diaria"
        @manutencao_programada.data_prevista + 1.day
      when "semanal"
        @manutencao_programada.data_prevista + 1.week
      when "quinzenal"
        @manutencao_programada.data_prevista + 15.days
      when "mensal"
        @manutencao_programada.data_prevista + 1.month
      when "bimestral"
        @manutencao_programada.data_prevista + 2.months
      when "trimestral"
        @manutencao_programada.data_prevista + 3.months
      when "quadrimestral"
        @manutencao_programada.data_prevista + 4.months
      when "semestral"
        @manutencao_programada.data_prevista + 6.months
      when "anual"
        @manutencao_programada.data_prevista + 1.year
      when "bienal"
        @manutencao_programada.data_prevista + 2.years
      when "trienal"
        @manutencao_programada.data_prevista + 3.years
      else
        nil
      end

    if nova_data
      @manutencao_programada.update(data_prevista: nova_data)
      redirect_to manutencao_programadas_path, notice: "Manutenção adiada para #{I18n.l(nova_data)}."
    else
      redirect_to manutencao_programadas_path, alert: "Periodicidade não reconhecida para adiar."
    end
  end

  private

  def set_manutencao_programada
    @manutencao_programada = ManutencaoProgramada.find(params[:id])
  end

    def require_operador_ou_admin!
    permitido = current_user&.admin? || current_user&.role == "operador"
    return if permitido

    respond_to do |format|
      format.html { redirect_to dashboard_path, alert: "Você não tem permissão para executar esta ação." }
      format.json { render json: { error: "forbidden" }, status: :forbidden }
    end
  end

  def manutencao_programada_params
    params.require(:manutencao_programada).permit(:titulo, :categoria, :local, :responsavel, :periodicidade, :data_prevista, :dias_para_aviso, :observacao, :exibir_no_app, :data_de_aviso)
  end
end
