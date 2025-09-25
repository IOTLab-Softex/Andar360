class CreateManutencaoProgramadas < ActiveRecord::Migration[8.0]
  def change
    create_table :manutencao_programadas do |t|
      t.string :titulo
      t.string :categoria
      t.string :local
      t.string :responsavel
      t.string :periodicidade
      t.date :data_prevista
      t.date :data_de_aviso
      t.integer :dias_para_aviso
      t.text :observacao
      t.boolean :exibir_no_app

      t.timestamps
    end
  end
end
