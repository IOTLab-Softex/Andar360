class CreateImportLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :import_logs do |t|
      t.string :nome
      t.string :cpf
      t.string :status
      t.text :mensagem
      t.boolean :dados_incompletos
      t.boolean :sem_foto

      t.timestamps
    end
  end
end
