class CreateSubGrupoEmpresas < ActiveRecord::Migration[8.0]
  def change
    create_table :sub_grupo_empresas do |t|
      t.string :nome
      t.references :grupo_empresa, null: false, foreign_key: true

      t.timestamps
    end
  end
end
