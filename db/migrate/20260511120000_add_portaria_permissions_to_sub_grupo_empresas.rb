class AddPortariaPermissionsToSubGrupoEmpresas < ActiveRecord::Migration[8.0]
  def change
    add_column :sub_grupo_empresas, :can_manage_items, :boolean, default: false, null: false
    add_column :sub_grupo_empresas, :can_manage_encomendas, :boolean, default: false, null: false
  end
end
