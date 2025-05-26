class GrupoEmpresasController < ApplicationController
 before_action :authenticate_user!
  before_action :authorize_admin!, only: [:new, :create, :destroy]
  before_action :set_grupo_empresa, only: [:edit, :update]

  def index
    @grupo_empresas = scoped_grupo_empresas
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
    @grupo_empresa = GrupoEmpresa.find(params[:id])
  end

  def destroy
  @grupo_empresa.destroy
  redirect_to grupo_empresas_path, notice: "Empresa excluída com sucesso."
end


  def update
    @grupo_empresa = GrupoEmpresa.find(params[:id])
    if @grupo_empresa.update(grupo_empresa_params)
      redirect_to grupo_empresas_path, notice: "Empresa atualizada com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def authorize_admin!
    unless current_user&.admin?
      redirect_to root_path, alert: "Acesso não autorizado."
    end
  end

  def set_grupo_empresa
  @grupo_empresa = GrupoEmpresa.find(params[:id])
end

  def grupo_empresa_params
    params.require(:grupo_empresa).permit(:nome, :logo, :sala, :andar)
  end
end
