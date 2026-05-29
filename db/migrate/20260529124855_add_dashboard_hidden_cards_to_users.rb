class AddDashboardHiddenCardsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :dashboard_hidden_cards, :jsonb, default: [], null: false
  end
end
