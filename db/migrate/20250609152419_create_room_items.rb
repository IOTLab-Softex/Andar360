class CreateRoomItems < ActiveRecord::Migration[7.0]
  def change
    create_table :room_items do |t|
      t.references :room, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :quantity, null: false, default: 1

      t.timestamps
    end
  end
end
