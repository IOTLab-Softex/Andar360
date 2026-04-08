class AddPasswordRecoveryFieldsToChamados < ActiveRecord::Migration[8.0]
  def change
    add_column :chamados, :password_recovery_support_request, :boolean, default: false, null: false
    add_column :chamados, :password_recovery_reset_link_sent_at, :datetime
  end
end
