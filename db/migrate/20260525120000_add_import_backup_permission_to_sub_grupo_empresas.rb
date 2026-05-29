class AddImportBackupPermissionToSubGrupoEmpresas < ActiveRecord::Migration[8.0]
  def change
    add_column :sub_grupo_empresas, :can_manage_import_backup, :boolean, default: false, null: false
  end
end
