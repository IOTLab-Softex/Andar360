class GrupoEmpresasController < ApplicationController
  before_action :authenticate_user!

  # 🔒 Admin obrigatório só para: novo, criar, destruir
  before_action :authorize_admin!, only: [:new, :create, :destroy]

  # carrega a empresa antes de editar/atualizar/destruir
  before_action :set_grupo_empresa, only: [:edit, :update, :destroy]

  # 🔐 Regra específica pra quem pode editar/atualizar
  before_action :authorize_edit_grupo_empresa!, only: [:edit, :update]

  def index
    @grupo_empresas = scoped_grupo_empresas
    if params[:search].present?
      @grupo_empresas = @grupo_empresas.where("nome ILIKE ?", "%#{params[:search]}%")
    end
  end

  def new
    @grupo_empresa = GrupoEmpresa.new
  end

  def create
    @grupo_empresa = GrupoEmpresa.new(grupo_empresa_params)
    if @grupo_empresa.save
      redirect_to grupo_empresas_path, notice: "Empresa cadastrada com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # @grupo_empresa já vem do before_action :set_grupo_empresa
  end

  def update
    if @grupo_empresa.update(grupo_empresa_params)
      redirect_to grupo_empresas_path, notice: "Empresa atualizada com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @grupo_empresa.destroy
    redirect_to grupo_empresas_path, notice: "Empresa excluída com sucesso."
  end

  private

  # ✳️ Admin full power (new/create/destroy), cliente só passa aqui se não cair na regra de edição
  def authorize_admin!
    unless current_user&.admin?
      redirect_to root_path, alert: "Acesso não autorizado."
    end
  end

  def set_grupo_empresa
    @grupo_empresa = GrupoEmpresa.find(params[:id])
  end

  # ✅ Aqui liberamos o CLIENTE a editar apenas a própria empresa
  def authorize_edit_grupo_empresa!
    return if current_user&.admin? # admin sempre pode

    # pega a empresa vinculada ao usuário (via participant)
    user_empresa_id = current_user.participant&.grupo_empresa_id

    unless user_empresa_id.present? && user_empresa_id == @grupo_empresa.id
      redirect_to root_path, alert: "Você não tem permissão para editar esta empresa."
    end
  end

def grupo_empresa_params
  # Admin pode tudo
  if current_user&.admin?
    params.require(:grupo_empresa)
          .permit(:nome, :logo, :sala, :andar, :cnpj)
  else
    # Cliente só pode mexer em coisas "seguras"
    # (por enquanto deixei só :logo, ajusta conforme o que você quiser liberar)
    params.require(:grupo_empresa)
          .permit(:logo)
  end
end

end
