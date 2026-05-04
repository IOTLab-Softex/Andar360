class CreateAnnouncementViews < ActiveRecord::Migration[8.0]
  def change
    create_table :announcement_views do |t|
      t.references :user,         null: false, foreign_key: true
      t.references :announcement, null: false, foreign_key: true
      t.timestamps
    end

    add_index :announcement_views, [:user_id, :announcement_id], unique: true
  end
end
