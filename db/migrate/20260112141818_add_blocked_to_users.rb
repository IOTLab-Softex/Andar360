class AddBlockedToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :blocked, :boolean, default: false, null: false unless column_exists?(:users, :blocked)
    add_index  :users, :blocked unless index_exists?(:users, :blocked)
  end
end
