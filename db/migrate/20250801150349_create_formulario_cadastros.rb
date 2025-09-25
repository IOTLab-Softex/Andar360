class CreateFormularioCadastros < ActiveRecord::Migration[8.0]
  def change
    create_table :formulario_cadastros do |t|
      t.string :nome
      t.string :cpf
      t.string :telefone
      t.string :email
      t.string :cargo
      t.string :horario_trabalho
      t.string :dias_trabalho
      t.boolean :concorda_termos
      t.text :observacao

      t.timestamps
    end
  end
end
