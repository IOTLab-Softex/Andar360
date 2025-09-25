class CreateOcorrencia < ActiveRecord::Migration[8.0]
  def change
    create_table :ocorrencia do |t|
      t.references :manutencao_programada, null: false, foreign_key: true
      t.date :data_ocorrencia
      t.date :proxima_data
      t.text :descricao

      t.timestamps
    end
  end
end
