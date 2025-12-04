# db/migrate/20251020_make_room_id_nullable_and_add_cols_to_room_items.rb
class MakeRoomIdNullableAndAddColsToRoomItems < ActiveRecord::Migration[8.0]
  def change
    # Se a tabela não existir (como é o caso no seu Postgres novo),
    # essa migration simplesmente não faz nada e não quebra.
    return unless table_exists?(:room_items)

    change_column_null :room_items, :room_id, true  # permite catálogo global (room_id NULL)

    unless column_exists?(:room_items, :modelo)
      add_column :room_items, :modelo, :string
    end

    unless column_exists?(:room_items, :valor)
      add_column :room_items, :valor, :decimal, precision: 12, scale: 2
    end

    unless index_exists?(:room_items, :name)
      add_index :room_items, :name
    end
  end
end
