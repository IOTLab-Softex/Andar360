class RoomsController < ApplicationController
  before_action :authenticate_user!

   # Operador OU Admin podem ver/listar/abrir formulário/criar/editar
   before_action :authorize_admin_or_operator!, only: [:index, :show, :new, :create, :edit, :import]
   # A abertura de porta é controlada por permissão do subgrupo (can_open_doors)
   before_action :authorize_open_door!, only: [:open_door]

  # Apenas Admin nas demais ações (update/destroy, etc.)
  before_action :authorize_admin!, except: [:index, :show, :new, :create, :edit, :open_door, :import, :reservations_json, :rules]

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

  carregar_empresas
  @catalog_items = RoomItem.catalog.order(:name)

end


  # GET /rooms/1/edit
  def edit
    carregar_empresas
    @catalog_items = RoomItem.catalog.order(:name)
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
      @catalog_items = RoomItem.catalog.order(:name)

      format.html { render :new, status: :unprocessable_entity }
      format.json { render json: @room.errors, status: :unprocessable_entity }
    end
  end
end


  def open_door
    room = Room.find(params[:id])
    device = room.device # Supondo que cada Room tem um Device associado
    Rails.logger.info "[AI AGENT] RoomsController#open_door user_id=#{current_user&.id} role=#{current_user&.role} room_id=#{room.id} device_present=#{device.present?}"

    if device.present? && device_online_for_door?(device)
      OpenDoorJob.perform_later(device.ip, device.user, device.password)
      flash[:notice] = "Comando para abrir a porta enviado!"
    elsif device.present?
      flash[:alert] = "A sala #{room.name} esta offline."
    else
      flash[:alert] = "Dispositivo não encontrado para essa sala."
    end
    redirect_to dashboard_path
  end

def rules
  @room = Room.find(params[:id])

  html_room_observation =
    @room.try(:observacao)&.body&.to_s.presence

  html_room_rules =
    @room.try(:rules)&.body&.to_s.presence ||
    @room.try(:regras_de_uso)&.body&.to_s.presence

  html_global =
    Setting.first&.try(:room_rules)&.body&.to_s # se você declarou has_rich_text :room_rules no model Setting

  html = []
  if html_room_observation.present?
    html << view_context.content_tag(:h3, "Observacoes da sala")
    html << html_room_observation
  end

  rules_html = html_room_rules.presence || html_global.presence
  if rules_html.present?
    html << view_context.content_tag(:h3, "Regras de uso")
    html << rules_html
  end

  render html: html.join.html_safe, layout: false
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
    Room.where(id: ids).find_each do |room|
      detach_room_devices!(room)
      room.destroy!
    end
  end

  redirect_to rooms_path, notice: "#{ids.size} sala(s) removida(s) com sucesso."
rescue => e
  redirect_to rooms_path, alert: "Falha ao excluir em massa: #{e.message}"
end

  # PATCH/PUT /rooms/1 or /rooms/1.json
def update
  respond_to do |format|
    if @room.update(room_params)
      format.html { redirect_to rooms_path, notice: "Room was successfully updated." }
      format.json { render :show, status: :ok, location: @room }
    else
      carregar_empresas
      @catalog_items = RoomItem.catalog.order(:name)

      format.html { render :edit, status: :unprocessable_entity }
      format.json { render json: @room.errors, status: :unprocessable_entity }
    end
  end
end


  # DELETE /rooms/1 or /rooms/1.json
  def destroy
    Room.transaction do
      detach_room_devices!(@room)
      @room.destroy!
    end

    respond_to do |format|
      format.html { redirect_to rooms_path, status: :see_other, notice: "Sala excluida com sucesso!" }
      format.json { head :no_content }
    end
  end

def reservations_json
  room = Room.find(params[:id])

  reservas = room.reservations
                 .where(cancelada_em: nil)
                 .where("ends_at > ?", Time.current)
                 .order(:starts_at)
                 .select(:starts_at, :ends_at)

  itens = room.room_items.map do |ri|
    { name: ri.name, quantity: ri.quantity, icon_svg: icon_html_for(ri) }
  end

  render json: {
    reservas: reservas.map { |r| { starts_at: r.starts_at, ends_at: r.ends_at } },
    itens: itens
  }
end


private

def icon_filename_for(name)
  # mapeie NOME → arquivo SVG dentro de app/assets/images/icons
  case name
  when "TV"             then "icons/fa-tv.svg"
  when "Cadeiras"       then "icons/fa-chair.svg"
  when "Mesa"           then "icons/fa-table.svg"
  when "Telefone"       then "icons/fa-phone.svg"
  when "Lousa"          then "icons/fa-chalkboard.svg"
  when "Projetor"       then "icons/fa-video.svg"
  when "Ar Condicionado" then "icons/fa-fan.svg"     # escolha um equivalente
  when "HDMI"           then "icons/fa-plug.svg"     # não existe 'hdmi' no FA, escolha similar
  when "Tomadas"        then "icons/fa-plug.svg"
  else                      "icons/fa-circle-question.svg" # fallback
  end
end

def icon_html_for(room_item)
  return "" unless room_item.icon.attached?

  ct = room_item.icon.content_type

  if ct == "image/svg+xml"
    data = room_item.icon.download.force_encoding("UTF-8")
    data.gsub!(/\s*(width|height|fill|style)="[^"]*"/, "")
    data.gsub!("<svg", '<svg fill="currentColor"')

    frag = Nokogiri::HTML::DocumentFragment.parse(data)
    svg  = frag.at_css("svg")
    return "" unless svg

    frag.css("script, foreignObject").remove
    frag.traverse do |n|
      next unless n.element?
      n.attribute_nodes.select { |a| a.name.downcase.start_with?("on") }.each(&:remove)
    end

    svg["style"] ||= "height:13px; fill:currentColor; vertical-align:middle;"
    frag.to_html
  else
    view_context.image_tag(
      Rails.application.routes.url_helpers.url_for(room_item.icon),
      alt: room_item.name,
      style: "height:13px; vertical-align:middle;"
    )
  end
end


def fallback_icon(room_item)
  view_context.svg_icon(icon_filename_for(room_item.name))
end

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

  def authorize_open_door!
    unless current_user&.admin? || current_user&.operador? || subgrupo_permission_enabled?(:can_open_doors)
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

    def device_online_for_door?(device)
      device.status.to_s.downcase == "online"
    end

    # Only allow a list of trusted parameters through.
   def room_params
  params.require(:room).permit(
    :name, :grupo, :virtual, :alugado, :unidade_vazia, :ativo,
    :espaco_comun, :categoria, :capacidade, :taxa, :device_id,
    :area, :matricula, :fracao_ideal, :fracao_extra,
    :interfone, :vagas_garagem, :empresa_proprietaria, :proprietario_formal,
    :dados_do_inquilino, :observacao, :regras_de_uso,
    :photo,:room_group_id,
    room_items_attributes: [:id, :name, :quantity, :_destroy, :catalog_item_id]
  )
end

def detach_room_devices!(room)
  Device.where(room_id: room.id).update_all(room_id: nil)
end





end
