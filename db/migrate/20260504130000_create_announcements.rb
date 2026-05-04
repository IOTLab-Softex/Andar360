class CreateAnnouncements < ActiveRecord::Migration[8.0]
  def change
    create_table :announcements do |t|
      t.string  :title
      t.text    :body
      t.boolean :active, default: true, null: false
      t.references :created_by, null: true, foreign_key: { to_table: :users }
      t.timestamps
    end
  end
end
