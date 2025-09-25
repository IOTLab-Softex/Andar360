class EncomendasController < ApplicationController
  before_action :set_encomenda, only: %i[show edit update destroy entregar]

  # GET /encomendas or /encomendas.json
  def index
    @encomendas = Encomenda.all
      @encomendas_nao_entregues = Encomenda.nao_entregues
  @encomendas_entregues = Encomenda.entregues

    # Filtro por status
  if params[:status].present?
    if params[:status] == "entregue"
      @encomendas = @encomendas.where(entregue: true)  # troque pelo nome real do seu campo boolean
    elsif params[:status] == "pendente"
      @encomendas = @encomendas.where(entregue: [false, nil])
    end
  end

  # Filtro por empresa
  if params[:empresa].present?
    @encomendas = @encomendas.joins(:destinatario).where(participants: { grupo_empresa_id: params[:empresa] })
  end

  end

  # GET /encomendas/1 or /encomendas/1.json
  def show
  end

  def entregar
    @encomenda.update!(
      entregue: true,
      entregue_em: Time.current,
      # ajuste conforme sua UI: pode vir de params[:recebido_por_id]
      recebido_por_id: params[:recebido_por_id],
      # se quiser gravar o usuário do sistema que marcou a entrega:
      # entregue_por_id: current_user&.id
    )
    redirect_to @encomenda, notice: "Encomenda marcada como entregue."
  end
  # GET /encomendas/new
  def new
    @encomenda = Encomenda.new
    @encomenda = Encomenda.new(notificar_destinatario: true)
  end

  # GET /encomendas/1/edit
  def edit
  end

  # POST /encomendas or /encomendas.json
  def create
    @encomenda = Encomenda.new(encomenda_params)

    respond_to do |format|
      if @encomenda.save
        format.html { redirect_to encomendas_path, notice: "Encomenda was successfully created." }
        format.json { render :show, status: :created, location: @encomenda }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @encomenda.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /encomendas/1 or /encomendas/1.json
  def update
    respond_to do |format|
      if @encomenda.update(encomenda_params)
        format.html { redirect_to encomendas_path, notice: "Encomenda was successfully updated." }
        format.json { render :show, status: :ok, location: @encomenda }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @encomenda.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /encomendas/1 or /encomendas/1.json
  def destroy
    @encomenda.destroy!

    respond_to do |format|
      format.html { redirect_to encomendas_path, status: :see_other, notice: "Encomenda was successfully destroyed." }
      format.json { head :no_content }
    end
  end

   def marcar_entregue
    @encomenda = Encomenda.find(params[:id])
    @encomenda.update(entregue: true, recebido_por_id: params[:recebido_por_id], entregue_em: Time.current)

    redirect_to encomendas_path, notice: 'Encomenda marcada como entregue.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_encomenda
      @encomenda = Encomenda.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def encomenda_params
  params.require(:encomenda).permit(
    :unidade, :codigo, :transportadora, :tipo, :tamanho, :remetente,
    :destinatario_id, :observacao, :imagem, :notificar_destinatario
  )
end

end
