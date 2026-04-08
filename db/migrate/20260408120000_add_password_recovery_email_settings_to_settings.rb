class AddPasswordRecoveryEmailSettingsToSettings < ActiveRecord::Migration[8.0]
  def change
    change_table :settings, bulk: true do |t|
      t.boolean :password_recovery_test_mode, default: true, null: false
      t.string :password_recovery_test_host, default: "localhost:3000"
      t.string :password_recovery_live_host, default: "softexsrs.ddns.net"
      t.string :password_recovery_link_path, default: "/users/password/edit"
      t.string :password_recovery_email_subject
      t.text :password_recovery_email_html
    end
  end
end
