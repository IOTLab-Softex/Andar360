class CreateGrupoEmpresas < ActiveRecord::Migration[8.0]
  def change
    create_table :grupo_empresas do |t|
      t.string :nome

      t.timestamps
    end
  end
end
