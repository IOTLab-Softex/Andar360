class ChamadosController < ApplicationController
   include VisualizacaoHelper
  before_action :set_chamado, only: %i[ show edit update destroy ]
before_action :authenticate_user!

  # GET /chamados or /chamados.json
  def index
    if current_user&.admin? || current_user&.operador?
  @chamados = Chamado.all
else
  grupo_empresa_id = current_user.participant&.grupo_empresa_id
  @chamados = Chamado.joins(:solicitante).where(participants: { grupo_empresa_id: grupo_empresa_id })
end

    if params[:local].present? && params[:local] != "Todos os locais"
    @chamados = @chamados.where(local: params[:local])
  end

  if params[:unidade].present? && params[:unidade] != "Todas as unidades"
    @chamados = @chamados.where(unidade: params[:unidade])
  end

  if params[:status].present? && params[:status] != "Todos os status"
    @chamados = @chamados.where(status: params[:status])
  end

  if params[:prioridade].present? && params[:prioridade] != "Todas as prioridades"
    @chamados = @chamados.where(prioridade: params[:prioridade])
  end

  if params[:responsavel].present? && params[:responsavel] != "Todos os responsáveis"
    @chamados = @chamados.where(responsavel: params[:responsavel])
  end

  if params[:data_inicio].present? && params[:data_fim].present?
    @chamados = @chamados.where(data_resolucao: params[:data_inicio]..params[:data_fim])
  end
  end

  # GET /chamados/1 or /chamados/1.json
  def show
marcar_como_visualizado("chamado", @chamado.id)

  end

  # GET /chamados/new
 def new

  if current_user.admin? || current_user.operador?
    @rooms_disponiveis = Room.where(espaco_comun: false).order(:name)
  else
    grupo_empresa = current_user.participant&.grupo_empresa&.nome
    @rooms_disponiveis = Room.where(espaco_comun: false).where("lower(dados_do_inquilino) LIKE ?", "%#{grupo_empresa&.downcase}%")
  end
  if current_user.admin? || current_user.role == "operador"
  @possiveis_responsaveis = Participant.order(:name)
else
  grupo_id = current_user.participant&.grupo_empresa_id
  @possiveis_responsaveis = Participant.where(grupo_empresa_id: grupo_id).order(:name)
end
  last_os_number = Chamado.order(:created_at).last&.id.to_i + 1
  os_formatada = "%04d" % last_os_number
  @chamado = Chamado.new(os: os_formatada)
  @chamado.responsavel ||= current_user.participant&.name

  @chamado.room_id ||= @rooms_disponiveis.first.id if @rooms_disponiveis.size == 1

end


  # GET /chamados/1/edit
  def edit
     if current_user.admin?
    @rooms_disponiveis = Room.where(espaco_comun: false).order(:name)
  else
    grupo_empresa = current_user.participant&.grupo_empresa&.nome
    @rooms_disponiveis = Room.where(espaco_comun: false).where("lower(dados_do_inquilino) LIKE ?", "%#{grupo_empresa&.downcase}%")
  end
  if current_user.admin? || current_user.role == "operador"
  @possiveis_responsaveis = Participant.order(:name)
else
  grupo_id = current_user.participant&.grupo_empresa_id
  @possiveis_responsaveis = Participant.where(grupo_empresa_id: grupo_id).order(:name)
end

  @chamado.room_id ||= @rooms_disponiveis.first.id if @rooms_disponiveis.size == 1

  end

  # POST /chamados or /chamados.json
def create
  puts "Usuário logado: #{current_user&.name.inspect}"

  last_os_number = Chamado.order(:created_at).last&.id.to_i + 1
  os_formatada = "%04d" % last_os_number

  participant = current_user.participant

params_sanitizados = chamado_params.dup

# Força status = "Pendente" se não for admin nem operador
unless current_user.admin? || current_user.role == "operador"
  params_sanitizados[:status] = "Pendente"
end

@chamado = Chamado.new(params_sanitizados.merge(
  os: os_formatada,
  solicitante: participant,
  solicitante_nome: participant&.name
))

  respond_to do |format|
    if @chamado.save
      format.html { redirect_to root_path, notice: "Chamado criado com sucesso." }
      format.json { render :show, status: :created, location: @chamado }
    else
      format.html { render :new, status: :unprocessable_entity }
      format.json { render json: @chamado.errors, status: :unprocessable_entity }
    end
  end
end



def update
  respond_to do |format|
    if @chamado.update(chamado_params.except(:fotos))
      if params[:chamado][:fotos]
        @chamado.fotos.attach(params[:chamado][:fotos])
      end
      format.html { redirect_to root_path, notice: "Chamado atualizado com sucesso." }
    else
      format.html { render :edit, status: :unprocessable_entity }
    end
  end
end


  # DELETE /chamados/1 or /chamados/1.json
  def destroy
    @chamado.destroy!

    respond_to do |format|
      format.html { redirect_to root_path, status: :see_other, notice: "Chamado excluído com sucesso." }

      format.json { head :no_content }
    end
  end
  
def remove_foto
  foto = ActiveStorage::Blob.find_signed(params[:foto_id])
  foto.attachments.first&.purge_later
  redirect_back fallback_location: chamados_path, notice: "Foto removida com sucesso."
end

 def anexar_arquivo
    @chamado = Chamado.find(params[:id])
    arquivo_anexo = @chamado.arquivos_anexos_chamado.build(nome: params[:nome])
    arquivo_anexo.arquivo.attach(params[:arquivo])

    if arquivo_anexo.save
      redirect_to edit_chamado_path(@chamado), notice: "Arquivo anexado com sucesso."
    else
      redirect_to edit_chamado_path(@chamado), alert: "Erro ao anexar o arquivo."
    end
  end
  
  private
    # Use callbacks to share common setup or constraints between actions.
def set_chamado
  @chamado = Chamado.find(params[:id])
end


    # Only allow a list of trusted parameters through.
def chamado_params
  params.require(:chamado).permit(:room_id, :os, :titulo, :prioridade, :status, :data_resolucao, :exibir_no_app, :local, :responsavel, :observacao, fotos: [])
end

 def chamado_params_com_anexo
    params.require(:chamado).permit(:nome, :arquivo) # Certifique-se de permitir os atributos 'nome' e 'arquivo'
  end

end
