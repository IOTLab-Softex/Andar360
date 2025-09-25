class CreateChamados < ActiveRecord::Migration[8.0]
  def change
    create_table :chamados do |t|
      t.string :os
      t.string :unidade
      t.string :titulo
      t.string :prioridade
      t.string :status
      t.date :data_resolucao
      t.boolean :exibir_no_app
      t.string :local
      t.string :responsavel
      t.text :observacao

      t.timestamps
    end
  end
end
