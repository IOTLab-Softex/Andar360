class AddItSupportFlagsToSubGrupoEmpresas < ActiveRecord::Migration[8.0]
  def change
    add_column :sub_grupo_empresas, :can_view_monitoring, :boolean, default: false, null: false
  end
end
