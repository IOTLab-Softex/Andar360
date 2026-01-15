class AddWebpushKeysToSettings < ActiveRecord::Migration[8.0]
  def change
    add_column :settings, :vapid_public_key, :string
    add_column :settings, :vapid_private_key, :string
    add_column :settings, :vapid_subject, :string
  end
end
