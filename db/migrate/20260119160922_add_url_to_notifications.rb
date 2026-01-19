class AddUrlToNotifications < ActiveRecord::Migration[8.0]
  def change
    add_column :notifications, :url, :string
  end
end
