class AddNotificationPreferencesToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :notification_preferences, :jsonb, default: %w[info success warning system], null: false
  end
end
