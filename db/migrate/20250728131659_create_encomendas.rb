class CreateEncomendas < ActiveRecord::Migration[8.0]
  def change
    create_table :encomendas do |t|
      t.string :unidade
      t.string :codigo
      t.string :transportadora
      t.string :tipo
      t.string :tamanho
      t.string :remetente
      t.string :destinatario
      t.text :observacao

      t.timestamps
    end
  end
end
