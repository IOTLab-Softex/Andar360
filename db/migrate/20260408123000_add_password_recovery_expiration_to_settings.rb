class AddPasswordRecoveryExpirationToSettings < ActiveRecord::Migration[8.0]
  def change
    add_column :settings, :password_recovery_expiration_minutes, :integer, default: 360, null: false
  end
end
