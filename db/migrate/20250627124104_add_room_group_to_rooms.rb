class AddRoomGroupToRooms < ActiveRecord::Migration[8.0]
  def change
    add_reference :rooms, :room_group, null: true, foreign_key: true

  end
end
