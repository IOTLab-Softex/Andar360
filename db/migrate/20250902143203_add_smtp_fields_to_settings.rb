class AddSmtpFieldsToSettings < ActiveRecord::Migration[8.0]
  def change
    add_column :settings, :smtp_from_email, :string
    add_column :settings, :smtp_reply_to, :string
    add_column :settings, :smtp_address, :string
    add_column :settings, :smtp_port, :integer
    add_column :settings, :smtp_domain, :string
    add_column :settings, :smtp_username, :string
    add_column :settings, :smtp_password_ciphertext, :text
    add_column :settings, :smtp_authentication, :string
    add_column :settings, :smtp_enable_starttls_auto, :boolean
  end
end
