class AddAndar360AccessToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :can_access_andar360, :boolean, null: false, default: true
  end
end
