class RemoveObservacaoAndRegrasDeUsoFromRooms < ActiveRecord::Migration[8.0]
  def change
    remove_column :rooms, :observacao, :text
    remove_column :rooms, :regras_de_uso, :string
  end
end
