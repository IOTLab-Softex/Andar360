class UpdatePasswordRecoveryLiveHostDomain < ActiveRecord::Migration[8.0]
  OLD_HOST = "softexsrs.ddns.net".freeze
  NEW_HOST = "andar360.ddns.net".freeze

  def up
    change_column_default :settings, :password_recovery_live_host, from: OLD_HOST, to: NEW_HOST

    execute <<~SQL.squish
      UPDATE settings
      SET password_recovery_live_host = '#{NEW_HOST}'
      WHERE password_recovery_live_host IS NULL
         OR password_recovery_live_host = ''
         OR password_recovery_live_host = '#{OLD_HOST}'
         OR password_recovery_live_host = 'https://#{OLD_HOST}'
    SQL
  end

  def down
    change_column_default :settings, :password_recovery_live_host, from: NEW_HOST, to: OLD_HOST

    execute <<~SQL.squish
      UPDATE settings
      SET password_recovery_live_host = '#{OLD_HOST}'
      WHERE password_recovery_live_host = '#{NEW_HOST}'
         OR password_recovery_live_host = 'https://#{NEW_HOST}'
    SQL
  end
end
