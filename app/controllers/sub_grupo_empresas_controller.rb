class SubGrupoEmpresasController < ApplicationController
  
  def create
    @subgrupo = SubGrupoEmpresa.new(sub_grupo_empresa_params)
    if @subgrupo.save
      redirect_to edit_grupo_empresa_path(@subgrupo.grupo_empresa), notice: "Subgrupo adicionado com sucesso!"
    else
      redirect_back fallback_location: root_path, alert: "Erro ao adicionar subgrupo."
    end
  end
  
 def por_empresa
    subgrupos = SubGrupoEmpresa.where(grupo_empresa_id: params[:grupo_empresa_id])
    render json: subgrupos.map { |s| { id: s.id, nome: s.nome } }
  end

  def destroy
  @subgrupo = SubGrupoEmpresa.find(params[:id])
  @subgrupo.destroy
  render json: { success: true }
end


  private

  def sub_grupo_empresa_params
    params.permit(:nome, :grupo_empresa_id)
  end
end
