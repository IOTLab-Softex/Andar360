class AddCanSupportAccessToSubGrupoEmpresas < ActiveRecord::Migration[8.0]
  def change
    add_column :sub_grupo_empresas, :can_support_access, :boolean, default: false, null: false
  end
end
