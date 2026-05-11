class SubGrupoEmpresasController < ApplicationController
  before_action :authenticate_user!

  # se quiser, pode travar create/update/destroy só pra admin/operador
  # e liberar só o por_empresa pra cliente:
  # before_action :authorize_admin_or_operador!, except: [:por_empresa]

  def create
    @subgrupo = SubGrupoEmpresa.new(sub_grupo_empresa_params)

    if @subgrupo.save
      redirect_to edit_grupo_empresa_path(@subgrupo.grupo_empresa),
                  notice: "Subgrupo adicionado com sucesso!"
    else
      redirect_back fallback_location: root_path,
                    alert: "Erro ao adicionar subgrupo."
    end
  end

  # usado via AJAX pra buscar por empresa
  def por_empresa
    subgrupos = SubGrupoEmpresa.where(grupo_empresa_id: params[:grupo_empresa_id])
    render json: subgrupos.map { |s| { id: s.id, nome: s.nome } }
  end

  def update
    @sub_grupo_empresa = SubGrupoEmpresa.find(params[:id])

    if @sub_grupo_empresa.update(sub_grupo_empresa_params)
      redirect_to edit_grupo_empresa_path(@sub_grupo_empresa.grupo_empresa_id),
                  notice: "Subgrupo atualizado com sucesso."
    else
      redirect_back fallback_location: grupo_empresas_path,
                    alert: "Erro ao atualizar subgrupo."
    end
  end

  def destroy
    @subgrupo = SubGrupoEmpresa.find(params[:id])
    @subgrupo.destroy
    render json: { success: true }
  end

  private

  def sub_grupo_empresa_params
    # 🔐 Admin / operador: podem mudar também as permissões de compra
    if current_user&.admin? || current_user&.operador?
      params.require(:sub_grupo_empresa).permit(
        :nome,
        :grupo_empresa_id,
        :can_request_purchase,
        :can_approve_purchase,
        :can_buy,
        :can_view_monitoring,
        :can_support_access,
        :can_manage_items,
        :can_manage_encomendas
      )
    else
      # 👤 Cliente comum: só pode mudar nome (e empresa, se fizer sentido)
      params.require(:sub_grupo_empresa).permit(
        :nome,
        :grupo_empresa_id
      )
    end
  end

  # Opcional, se quiser garantir que só admin/operador mexam aqui:
  # def authorize_admin_or_operador!
  #   unless current_user&.admin? || current_user&.operador?
  #     redirect_to root_path, alert: "Acesso não autorizado."
  #   end
  # end
end
