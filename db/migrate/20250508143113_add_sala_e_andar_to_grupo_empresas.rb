class AddSalaEAndarToGrupoEmpresas < ActiveRecord::Migration[8.0]
  def change
    add_column :grupo_empresas, :sala, :string
    add_column :grupo_empresas, :andar, :string
  end
end
