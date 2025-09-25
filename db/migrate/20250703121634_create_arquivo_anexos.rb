class CreateArquivoAnexos < ActiveRecord::Migration[8.0]
  def change
    create_table :arquivo_anexos do |t|
      t.string :nome
      t.references :manutencao_programada, null: false, foreign_key: true

      t.timestamps
    end
  end
end
