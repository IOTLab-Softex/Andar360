class AddFieldsToRooms < ActiveRecord::Migration[8.0]
  def change
    add_column :rooms, :floor, :string
    add_column :rooms, :device_id, :integer
  end
end
