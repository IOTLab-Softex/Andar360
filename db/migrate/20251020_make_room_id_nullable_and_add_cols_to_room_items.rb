# db/migrate/20251020_make_room_id_nullable_and_add_cols_to_room_items.rb
class MakeRoomIdNullableAndAddColsToRoomItems < ActiveRecord::Migration[8.0]
  def change
    change_column_null :room_items, :room_id, true  # permite catálogo global (room_id NULL)
    add_column :room_items, :modelo, :string
    add_column :room_items, :valor,  :decimal, precision: 12, scale: 2
    # índice opcional para buscas no catálogo
    add_index :room_items, :name
  end
end
