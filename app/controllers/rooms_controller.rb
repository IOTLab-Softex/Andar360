class RoomsController < ApplicationController
  before_action :authenticate_user!

  # Operador OU Admin podem ver/listar/abrir formulário/criar/editar/abrir porta
 before_action :authorize_admin_or_operator!, only: [:index, :show, :new, :create, :edit, :open_door, :import]

  # Apenas Admin nas demais ações (update/destroy, etc.)
  before_action :authorize_admin!, except: [:index, :show, :new, :create, :edit, :open_door, :import]

  before_action :set_room, only: %i[show edit update destroy open_door]
  before_action :carregar_empresas, only: [:new, :edit, :create, :update]


  # GET /rooms or /rooms.json
  def index
    @rooms = Room.with_attached_photo
  end

  # GET /rooms/1 or /rooms/1.json
  def show
  end

  # GET /rooms/new
 def new
  @room = Room.new
  @room.room_items.build
  carregar_empresas
end


  # GET /rooms/1/edit
  def edit
    carregar_empresas
  end

  # POST /rooms or /rooms.json
  def create
    @room = Room.new(room_params)

    respond_to do |format|
      if @room.save
        format.html { redirect_to dashboard_path, notice: "Room was successfully created." }
        format.json { render :show, status: :created, location: @room }
      else
        carregar_empresas
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @room.errors, status: :unprocessable_entity }
      end
    end
  end

  def open_door
    room = Room.find(params[:id])
    device = room.device # Supondo que cada Room tem um Device associado
    if device.present?
      OpenDoorJob.perform_later(device.ip, device.user, device.password)
      flash[:notice] = "Comando para abrir a porta enviado!"
    else
      flash[:alert] = "Dispositivo não encontrado para essa sala."
    end
    redirect_to dashboard_path
  end

  # app/controllers/rooms_controller.rb
def import
  if params[:file].blank?
    redirect_back fallback_location: rooms_path, alert: "Selecione um arquivo .xls, .xlsx ou .csv." and return
  end

  result = RoomsImportService.call(params[:file])

  msg = []
  msg << "Importação concluída."
  msg << "Criadas: #{result[:created]}"    if result[:created] > 0
  msg << "Atualizadas: #{result[:updated]}" if result[:updated] > 0
  msg << "Grupos criados: #{result[:groups_created]}" if result[:groups_created].to_i > 0
  if result[:errors].any?
    msg << "Erros (#{result[:errors].size}):"
    result[:errors].first(5).each { |e| msg << "• #{e}" }
  end

  redirect_to rooms_path, notice: msg.join("<br>").html_safe
end


  def template
    # Gera um CSV “modelo” simples (também serve para Excel abrir)
    headers = RoomsImportService::HEADERS
    csv = CSV.generate(col_sep: "\t") do |out|
      out << headers
      # linha de exemplo opcional:
      out << [
        "101",                    # Unidade
        "Bloco A",               # Grupo
        "Fulano da Silva",       # Proprietário
        "123.456.789-00",        # Cpf/Cnpj
        "MG-12.345.678",         # RG
        "fulano@exemplo.com",    # Email (s;)
        "(81) 99999-1111",       # Fone 1
        "",                      # Fone 2
        "Não",                   # Publico
        "Empresa XYZ LTDA",      # Inquilino
        "12.345.678/0001-90",    # Cpf/Cnpj
        "", "", "", "Não",       # RG, Email(s;), Fone1, Publico
        "Sim",                   # Aluguel
        "Não",                   # Vazia
        "45,5",                  # Área (m2)
        "MAT-123",               # Matrícula do Imóvel
        "1/50",                  # Fração Ideal
        "",                      # Fração Extra
        "201",                   # Interfone
        "1",                     # Garagem
        "50000-000",             # Cep
        "Rua Tal",               # Endereço
        "100",                   # Número
        "Bairro Centro",         # Bairro
        "Sala 1",                # Complemento
        "Recife",                # Cidade
        "Beltrano",              # Proprietário Formal
        "123.456.789-00",        # Cpf/Cnpj
        "Observação qualquer",   # Observação
        "Não",                   # Virtual
        "Não"                    # Bloqueado
      ]
    end

    send_data csv, filename: "modelo_importacao_salas.xls", type: "application/vnd.ms-excel"
  end
# app/controllers/rooms_controller.rb
def bulk_destroy
  authorize Room  if defined?(RoomPolicy) # opcional, se usa Pundit
  ids = Array(params[:ids]).map(&:to_i).uniq
  if ids.blank?
    redirect_to rooms_path, alert: "Nenhuma sala selecionada."
    return
  end

  Room.transaction do
    Room.where(id: ids).find_each(&:destroy!)
  end

  redirect_to rooms_path, notice: "#{ids.size} sala(s) removida(s) com sucesso."
rescue => e
  redirect_to rooms_path, alert: "Falha ao excluir em massa: #{e.message}"
end

  # PATCH/PUT /rooms/1 or /rooms/1.json
  def update
    respond_to do |format|
      if @room.update(room_params)
        format.html { redirect_to dashboard_path, notice: "Room was successfully updated." }
        format.json { render :show, status: :ok, location: @room }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @room.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /rooms/1 or /rooms/1.json
  def destroy
    @room.destroy!

    respond_to do |format|
      format.html { redirect_to rooms_path, status: :see_other, notice: "Sala excluida com sucesso!" }
      format.json { head :no_content }
    end
  end

  private
  def carregar_empresas
  @empresas = GrupoEmpresa.all.pluck(:nome)
   @empresa_padrao = current_user&.participant&.grupo_empresa&.nome
end

  def authorize_admin!
    unless current_user&.admin?
      redirect_to root_path, alert: "Acesso não autorizado."
    end
  end

  def authorize_admin_or_operator!
  unless current_user&.admin? || current_user&.operador?
    redirect_to root_path, alert: "Acesso não autorizado."
  end
  
end

 def operador_ou_admin?
    current_user&.admin? || current_user&.respond_to?(:operador?) && current_user.operador?
    # ou, se você usa role string:
    # current_user&.admin? || current_user&.role == 'operator'
  end

    # Use callbacks to share common setup or constraints between actions.
    def set_room
       @room = Room.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
   def room_params
  params.require(:room).permit(
    :name, :grupo, :virtual, :alugado, :unidade_vazia, :ativo,
    :espaco_comun, :categoria, :capacidade, :taxa, :device_id,
    :area, :matricula, :fracao_ideal, :fracao_extra,
    :interfone, :vagas_garagem, :empresa_proprietaria, :proprietario_formal,
    :dados_do_inquilino, :observacao, :regras_de_uso,
    :photo,
    room_items_attributes: [:id, :name, :quantity, :_destroy]
  )
end


    
    
    
end
