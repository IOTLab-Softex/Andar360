class CreateAccessLogs < ActiveRecord::Migration[7.0]
  def change
    create_table :access_logs do |t|
      t.references :participant, null: false, foreign_key: true
      t.references :reservation, null: false, foreign_key: true
      t.datetime :accessed_at, null: false
      t.integer :method
      t.integer :similarity

      t.timestamps
    end
  end
end
