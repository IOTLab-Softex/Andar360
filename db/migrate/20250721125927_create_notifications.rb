class CreateNotifications < ActiveRecord::Migration[7.0]
  def change
    create_table :notifications do |t|
      t.string :titulo
      t.text :corpo
      t.boolean :lida, default: false
      t.references :user, null: false, foreign_key: true
      t.references :notificavel, polymorphic: true

      t.timestamps
    end
  end
end
