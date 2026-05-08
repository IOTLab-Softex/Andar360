class AddShowOnLoginToAnnouncements < ActiveRecord::Migration[8.0]
  def change
    add_column :announcements, :show_on_login, :boolean, default: false, null: false
  end
end
