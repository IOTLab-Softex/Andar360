class AddDashboardCardOrderToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :dashboard_card_order, :jsonb, default: [], null: false
  end
end
