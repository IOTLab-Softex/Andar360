# config/initializers/mail_settings.rb
begin
  # Pule em tasks de assets/migrate ou se o banco/tabela ainda não existem
  skip = defined?(Rails::Command) && (Rails::Command.const_defined?(:Assets) || ARGV.any? { |a| a =~ /\A(db|assets):/ })
  unless skip
    if ActiveRecord::Base.connected? &&
       ActiveRecord::Base.connection.data_source_exists?('settings') &&
       Setting.exists?
      MailSettings.apply!
    end
  end
rescue ActiveRecord::NoDatabaseError, ActiveRecord::StatementInvalid => e
  Rails.logger.warn("Mail settings skipped during boot: #{e.class}: #{e.message}")
end
