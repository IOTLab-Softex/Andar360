class AddPurchasePermissionsToSubGrupoEmpresas < ActiveRecord::Migration[8.0]
  def change
    add_column :sub_grupo_empresas, :can_request_purchase, :boolean, default: false, null: false
    add_column :sub_grupo_empresas, :can_approve_purchase, :boolean, default: false, null: false
    add_column :sub_grupo_empresas, :can_buy, :boolean, default: false, null: false
  end
end
