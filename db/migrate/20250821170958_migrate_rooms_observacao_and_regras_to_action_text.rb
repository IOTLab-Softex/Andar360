class MigrateRoomsObservacaoAndRegrasToActionText < ActiveRecord::Migration[7.1]
  # Modelo mínimo só para a migration
  class Room < ApplicationRecord
    self.table_name = "rooms"
  end

  def up
    say_with_time "Migrando texto de rooms -> action_text_rich_texts (se existir)" do
      # Copia 'observacao' se a coluna existir
      if column_exists?(:rooms, :observacao)
        Room.where.not(observacao: [nil, ""]).find_each do |room|
          ActionText::RichText.create!(
            name: "observacao",
            record_type: "Room",
            record_id: room.id,
            body: room[:observacao]
          )
        end
      end

      # Copia 'regras_de_uso' se a coluna existir
      if column_exists?(:rooms, :regras_de_uso)
        Room.where.not(regras_de_uso: [nil, ""]).find_each do |room|
          ActionText::RichText.create!(
            name: "regras_de_uso",
            record_type: "Room",
            record_id: room.id,
            body: room[:regras_de_uso]
          )
        end
      end
    end

    # Remove apenas se existir (evita erro PG::UndefinedColumn)
    remove_column :rooms, :observacao, :text   if column_exists?(:rooms, :observacao)
    remove_column :rooms, :regras_de_uso, :string if column_exists?(:rooms, :regras_de_uso)
  end

  def down
    # Recria as colunas (conteúdo não é rehidratado a partir do ActionText)
    add_column :rooms, :observacao, :text    unless column_exists?(:rooms, :observacao)
    add_column :rooms, :regras_de_uso, :string unless column_exists?(:rooms, :regras_de_uso)
  end
end
