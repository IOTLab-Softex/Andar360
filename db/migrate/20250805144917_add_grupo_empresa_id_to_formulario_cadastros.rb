class AddGrupoEmpresaIdToFormularioCadastros < ActiveRecord::Migration[8.0]
  def change
    add_column :formulario_cadastros, :grupo_empresa_id, :integer
  end
end
