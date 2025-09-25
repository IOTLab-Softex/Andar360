class CreateItems < ActiveRecord::Migration[8.0]
  def change
    create_table :items do |t|
      t.string :nome
      t.text :descricao
      t.string :status

      t.timestamps
    end
  end
end
