class AddCanOpenDoorsToSubGrupoEmpresas < ActiveRecord::Migration[7.0]
  def change
    add_column :sub_grupo_empresas, :can_open_doors, :boolean, default: false, null: false
  end
end
