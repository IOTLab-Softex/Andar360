class AddCnpjToGrupoEmpresas < ActiveRecord::Migration[8.0]
  def change
    add_column :grupo_empresas, :cnpj, :string
  end
end
