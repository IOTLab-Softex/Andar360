class AddApontiTvAccessToSubGrupoEmpresas < ActiveRecord::Migration[8.0]
  def change
    add_column :sub_grupo_empresas, :can_access_aponti_tv, :boolean, default: false, null: false
  end
end
