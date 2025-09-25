class CreateRoomGroups < ActiveRecord::Migration[8.0]
  def change
    create_table :room_groups do |t|
      t.string :name
      t.text :description

      t.timestamps
    end
  end
end
