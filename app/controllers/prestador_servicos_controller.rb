class PrestadorServicosController < ApplicationController
  before_action :authenticate_user!
    before_action :authorize_admin!
  before_action :set_prestador_servico, only: %i[ show edit update destroy ]

  # GET /prestador_servicos or /prestador_servicos.json
  def index
    @prestador_servicos = PrestadorServico.all
  end

  # GET /prestador_servicos/1 or /prestador_servicos/1.json
  def show
  end

  # GET /prestador_servicos/new
  def new
    @prestador_servico = PrestadorServico.new
  end

  # GET /prestador_servicos/1/edit
  def edit
  end

  # POST /prestador_servicos or /prestador_servicos.json
  def create
    @prestador_servico = PrestadorServico.new(prestador_servico_params)

    respond_to do |format|
      if @prestador_servico.save
        format.html { redirect_to @prestador_servico, notice: "Prestador servico was successfully created." }
        format.json { render :show, status: :created, location: @prestador_servico }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @prestador_servico.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /prestador_servicos/1 or /prestador_servicos/1.json
  def update
    respond_to do |format|
      if @prestador_servico.update(prestador_servico_params)
        format.html { redirect_to @prestador_servico, notice: "Prestador servico was successfully updated." }
        format.json { render :show, status: :ok, location: @prestador_servico }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @prestador_servico.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /prestador_servicos/1 or /prestador_servicos/1.json
  def destroy
    @prestador_servico.destroy!

    respond_to do |format|
      format.html { redirect_to prestador_servicos_path, status: :see_other, notice: "Prestador servico was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_prestador_servico
      @prestador_servico = PrestadorServico.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def prestador_servico_params
      params.expect(prestador_servico: [ :nome, :publicado_no_app, :bloqueado, :cpf, :rg, :outro_documento, :fone1, :fone2, :whatsapp, :email, :site, :idoso_ou_pne, :tipo_veiculo, :placa, :fabricante, :modelo, :cor, :nome_fantasia, :cnpj, :servicos, :observacao, :foto ])
    end
end
