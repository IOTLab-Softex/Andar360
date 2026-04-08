class AddPasswordRecoveryExpirationUnitToSettings < ActiveRecord::Migration[8.0]
  def change
    add_column :settings, :password_recovery_expiration_unit, :string, default: "minutes", null: false
  end
end
