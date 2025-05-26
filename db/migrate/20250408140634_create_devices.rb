class CreateDevices < ActiveRecord::Migration[8.0]
  def change
    create_table :devices do |t|
      t.string :name
      t.string :status
      t.string :ip
      t.string :user
      t.string :password
      t.references :room, null: true, foreign_key: true

      t.timestamps
    end
  end
end
