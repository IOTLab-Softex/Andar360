class CreateUserPresences < ActiveRecord::Migration[8.0]
  def change
    create_table :user_presences do |t|
      t.references :user, null: false, foreign_key: true
      t.date :presence_on, null: false

      t.timestamps
    end

    add_index :user_presences, [:user_id, :presence_on], unique: true
    add_index :user_presences, :presence_on
  end
end
